-- Required native functions aliases (for clarity)
local GetGameplayCamRot = GetGameplayCamRot
local GetEntityHeading = GetEntityHeading
local GetEntityCoords = GetEntityCoords
local GetStreetNameAtCoord = GetStreetNameAtCoord
local GetStreetNameFromHashKey = GetStreetNameFromHashKey
local GetNameOfZone = GetNameOfZone
local GetLabelText = GetLabelText

-- Computes heading based on user setting whether compass follows camera or player heading
local function GetHeading()
    if UserSettingsData and UserSettingsData.compassFollowCamera then
        local camRot = GetGameplayCamRot(0)
        local heading = (360 - (camRot.z + 360) % 360) % 360
        return heading
    else
        return GetEntityHeading(cache.ped)
    end
end

-- Get street names at player's position
local function GetStreetNames()
    local coords = GetEntityCoords(cache.ped)
    local streetHash1, streetHash2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(streetHash1)
    local street2 = streetHash2 > 0 and GetStreetNameFromHashKey(streetHash2) or nil
    if street2 then
        return street1 .. " / " .. street2, street1
    else
        return street1, street1
    end
end

-- Get speed limit for a given zone or road name
local function GetSpeedLimit(zoneOrName)
    if type(Config.SpeedLimits) ~= "table" then
        return false
    end
    return Config.SpeedLimits[zoneOrName] or false
end

-- Convert heading to cardinal direction string and return degrees
local function GetCardinalDirection()
    local heading = GetHeading()
    local directions = { "N", "NW", "W", "SW", "S", "SE", "E", "NE" }
    local index = math.floor((heading + 22.5) / 45) + 1
    if index > 8 then index = 1 end
    return directions[index], heading
end

-- Get zone name of the player's current location
local function GetAreaName()
    local coords = GetEntityCoords(cache.ped)
    local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
    local label = GetLabelText(zoneName)
    if label == "NULL" or label == nil then
        return zoneName
    else
        return label
    end
end

-- Generate ped headshot texture URL asynchronously
local function GeneratePedHeadshot()
    if not Config.ShowComponents.pedAvatar then
        return false
    end

    lib.waitFor(function()
        return cache.ped and DoesEntityExist(cache.ped)
    end, nil, 5000)

    local headshotId = RegisterPedheadshot(cache.ped)

    lib.waitFor(function()
        return IsPedheadshotReady(headshotId) and IsPedheadshotValid(headshotId)
    end, "Could not load ped headshot", 5000)

    local txdString = GetPedheadshotTxdString(headshotId)
    UnregisterPedheadshot(headshotId)
    return string.format("https://nui-img/%s/%s", txdString, txdString)
end

-- Get delay based on user performance mode
local function GetUpdateDelay()
    local mode = UserSettingsData and UserSettingsData.performanceMode
    if mode == "ultra" then return 200 end
    if mode == "performance" then return 300 end
    if mode == "lowResmon" then return 1000 end
    return 500
end

local isTalkingThreadRunning = false

-- Create thread to send "isTalking" status to NUI
function CreateIsTalkingThread()
    if isTalkingThreadRunning then return end
    isTalkingThreadRunning = true

    Citizen.CreateThread(function()
        while IsHudRunning do
            SendNUIMessage({
                type = "isTalking",
                isTalking = NetworkIsPlayerTalking(cache.playerId)
            })
            Citizen.Wait(100)
        end
        isTalkingThreadRunning = false
    end)
end

local isPlayerThreadRunning = false

-- Create main player HUD data thread
function CreatePlayerThread()
    if isPlayerThreadRunning then return end
    isPlayerThreadRunning = true

    Framework.Client.CreateEventListeners()
    local waitTime = GetUpdateDelay()

    Citizen.CreateThread(function()
        while IsHudRunning do
            if not cache.ped or Framework.Client.IsPlayerDead() then
                -- Handle dead or no ped situation if needed
                pedHealth = 0
                pedArmour = 0
            else
                pedHealth = GetEntityHealth(cache.ped) - 100
                pedArmour = GetPedArmour(cache.ped)
            end

            local oxygen = not IsEntityInWater(cache.ped) or GetPlayerUnderwaterTimeRemaining(cache.playerId)
            local hunger = Framework.CachedPlayerData.hunger or false
            local thirst = Framework.CachedPlayerData.thirst or false
            local stress = Framework.CachedPlayerData.stress or false
            local job = Framework.CachedPlayerData.job
            local gang = Framework.CachedPlayerData.gang
            local timeFormatted = string.format("%02d:%02d", GetClockHours(), GetClockMinutes())
            local cardinalDirection, heading = GetCardinalDirection()
            local streetName, streetShortName = GetStreetNames()
            local areaName = GetAreaName()
            local nearestPostal = GetNearestPostal()
            local speedLimit = GetSpeedLimit(streetShortName)

            local pedData = {
                health = pedHealth,
                armour = pedArmour,
                food = hunger,
                water = thirst,
                oxygen = oxygen,
                stress = stress,
                job = job,
                gang = gang,
                time = timeFormatted,
                playerId = cache.serverId,
                cash = Framework.CachedPlayerData.cash,
                bank = Framework.CachedPlayerData.bank,
                dirtyMoney = Framework.CachedPlayerData.dirtyMoney,
                micRange = Framework.CachedPlayerData.micRange,
                radioActive = Framework.CachedPlayerData.radioActive,
                radioChannel = LocalPlayer.state.radioChannel or 0,
                voiceModes = Framework.CachedPlayerData.voiceModes,
                cardinalDirection = cardinalDirection,
                heading = heading,
                streetName = streetName,
                areaName = areaName,
                nearestPostal = nearestPostal,
                speedLimit = speedLimit
            }

            SendNUIMessage({ type = "pedData", pedData = pedData })

            Citizen.Wait(waitTime)
        end
        isPlayerThreadRunning = false
    end)
end
