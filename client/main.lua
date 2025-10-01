local cache = {
    inVehicle = false,
    totalDistance = 0,
    lastPosition = nil,
    currentVehicle = nil,
    voiceMode = 2,
    voiceModes = {},
    usingRadio = false,
    isLoggedIn = false,
    PlayerData = {}
}

local exports_cache = {
    fuel = nil,
}

-- Simple debug - let's see what LegacyFuel actually has
if GetResourceState('LegacyFuel') == "started" then
    print("^2[DEBUG] LegacyFuel is running^7")
    
    -- Try to call a simple method to see what happens
    local success, result = pcall(function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle and vehicle ~= 0 then
            return exports.LegacyFuel:GetFuel(vehicle)
        end
        return nil
    end)
    
    if success then
        print("^2[DEBUG] LegacyFuel GetFuel works! Result: " .. tostring(result) .. "^7")
        exports_cache.fuel = exports.LegacyFuel
    else
        print("^1[DEBUG] LegacyFuel GetFuel failed: " .. tostring(result) .. "^7")
        
        -- Try GetFuelLevel instead
        local success2, result2 = pcall(function()
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle and vehicle ~= 0 then
                return exports.LegacyFuel:GetFuelLevel(vehicle)
            end
            return nil
        end)
        
        if success2 then
            print("^2[DEBUG] LegacyFuel GetFuelLevel works!^7")
            exports_cache.fuel = exports.LegacyFuel
        else
            print("^1[DEBUG] LegacyFuel GetFuelLevel also failed^7")
        end
    end
else
    print("^1[DEBUG] LegacyFuel not running^7")
end

-- Temporary hasSeatbelt function to prevent errors
function hasSeatbelt()
    return false
end
_G.hasSeatbelt = hasSeatbelt

AddEventHandler("pma-voice:radioActive", function(radioTalking)
    cache.usingRadio = radioTalking
end)

AddEventHandler('pma-voice:setTalkingMode', function(newTalkingRange)
    cache.voiceMode = newTalkingRange
end)

TriggerEvent("pma-voice:settingsCallback", function(voiceSettings)
    local voiceTable = voiceSettings.voiceModes
    for i = 1, #voiceTable do
        cache.voiceModes[i] = tostring(math.ceil((i / #voiceTable) * 100))
    end
end)

local function getPlayerData()
    return GetPlayerData()
end

local function waitForPlayerLoad()
    while not IsPlayerLoaded() do
        Wait(1000)
    end
    cache.PlayerData = getPlayerData()
    cache.isLoggedIn = true
    TriggerEvent("hud:client:LoadMap")
end

local function getLocation()
    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)

    if crossingHash ~= 0 then
        street = street .. ' & ' .. GetStreetNameFromHashKey(crossingHash)
    end

    return {
        street = street,
        area = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    }
end

local function getFuelLevel(vehicle)
    if exports_cache.fuel then
        local success, fuel = pcall(function()
            return exports_cache.fuel:GetFuel(vehicle)
        end)
        
        if success then
            return fuel
        end
        
        -- Try GetFuelLevel if GetFuel failed
        local success2, fuel2 = pcall(function()
            return exports_cache.fuel:GetFuelLevel(vehicle)
        end)
        
        if success2 then
            return fuel2
        end
    end
    
    -- Fallback to native
    return GetVehicleFuelLevel(vehicle)
end

local function getVehicleData(vehicle)
    local fuel = getFuelLevel(vehicle) or 0
    return {
        speed = math.ceil(GetEntitySpeed(vehicle) * 3.6),
        rpm = GetVehicleCurrentRpm(vehicle),
        gear = GetVehicleCurrentGear(vehicle),
        engine = GetIsVehicleEngineRunning(vehicle),
        fuel = math.ceil(fuel)
    }
end

local function updatePlayerInfo()
    local ped = PlayerPedId()

    cache.PlayerData = getPlayerData()

    local meta = cache.PlayerData.metadata or {}

    SendNUIMessage({
        type = 'updateHUD',
        health = GetEntityHealth(ped) - 100,
        armor = GetPedArmour(ped),
        hunger = meta.hunger or 100,
        thirst = meta.thirst or 100,
        stress = meta.stress or 0,
        stamina = 100
    })

    SendNUIMessage({
        type = 'updatePlayerInfo',
        data = {
            job = string.format('%s Â· %s', cache.PlayerData.job.label, cache.PlayerData.job.grade.name),
            cash = cache.PlayerData.money.cash,
            bank = cache.PlayerData.money.bank,
            id = GetPlayerServerId(PlayerId()),
            voice = {
                level = cache.voiceModes[cache.voiceMode],
                talking = NetworkIsPlayerTalking(PlayerId())
            }
        }
    })
end

local function updateVehicleStatus(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    local isDriving = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped

    if isDriving ~= cache.inVehicle then
        cache.inVehicle = isDriving
        DisplayRadar(isDriving)
        SendNUIMessage({ type = 'toggleVehicleHUD', show = isDriving })
    end

    SendNUIMessage({ type = 'setVehicleStatus', inVehicle = cache.inVehicle })
    return vehicle, isDriving
end

local function updateOdometer(vehicle, speed)
    if cache.currentVehicle ~= vehicle then
        cache.currentVehicle = vehicle
        cache.totalDistance = math.random(50000, 150000)
        cache.lastPosition = nil
    end

    if cache.lastPosition and speed > 1 then
        local currentPos = GetEntityCoords(vehicle)
        local distance = #(currentPos - cache.lastPosition)
        if distance > 0.5 and distance < 50 then
            cache.totalDistance = cache.totalDistance + (distance * 0.000621371)
        end
    end

    cache.lastPosition = GetEntityCoords(vehicle)
end

local function getGearDisplay(gear, engine)
    if gear == 0 then
        return "R"
    elseif gear == -1 then
        return "P"
    elseif not engine then
        return "N"
    else
        return gear
    end
end

local function updateVehicleHUD(vehicle)
    local vdata = getVehicleData(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local coords = GetEntityCoords(PlayerPedId())
    local location = getLocation()
    local _, lightsOn, highBeamsOn = GetVehicleLightsState(vehicle)

    updateOdometer(vehicle, vdata.speed)

    local speedMph = math.ceil(vdata.speed * 0.621371)
    local rpmValue = vdata.rpm * 10000
    local gearDisplay = getGearDisplay(vdata.gear, vdata.engine)

    SendNUIMessage({
        type = 'updateVehicle',
        speed = speedMph,
        fuel = vdata.fuel,
        engineHealth = math.ceil((engineHealth / 1000) * 100),
        odometer = math.ceil(cache.totalDistance),
        vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
        rpm = rpmValue,
        gear = gearDisplay,
        seatbeltOn = hasSeatbelt(),
        leftTurnSignal = GetVehicleIndicatorLights(vehicle) & 1 > 0,
        rightTurnSignal = GetVehicleIndicatorLights(vehicle) & 2 > 0,
        hazardLights = GetVehicleIndicatorLights(vehicle) == 3,
        headlights = lightsOn and highBeamsOn,
        shortLights = lightsOn,
        highLights = highBeamsOn,
        vehicleBroken = engineHealth < 300 or not vdata.engine,
        handbrake = GetVehicleHandbrake(vehicle),
        engineWarning = engineHealth < 500 or not vdata.engine
    })

    SendNUIMessage({
        type = 'updateLocation',
        street = location.street or 'UbicaciÃ³n desconocida',
        zone = location.area or 'Zona desconocida',
        coordinates = string.format('%.0f', math.sqrt(coords.x ^ 2 + coords.y ^ 2)),
        distance = string.format('%.0fÂ°', GetEntityHeading(PlayerPedId()))
    })
end

CreateThread(waitForPlayerLoad)

CreateThread(function()
    while true do
        if cache.isLoggedIn then
            local ped = PlayerPedId()
            updatePlayerInfo()

            local vehicle, isDriving = updateVehicleStatus(ped)

            if cache.inVehicle then
                updateVehicleHUD(vehicle)
            end
        end
        Wait(cache.inVehicle and 100 or 1000)
    end
end)