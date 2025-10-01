local TrainDistanceLimit = 50.0
local lastNearestStation = nil
local lastStationDirection = nil

-- Calculates rounded 3D distance between two vectors
local function GetDistanceRounded(vec1, vec2)
    return math.round(#(vector3(vec1.x, vec1.y, vec1.z) - vector3(vec2.x, vec2.y, vec2.z)))
end

-- Calculates bearing angle (in degrees) between 2D points
local function CalculateBearing(pos1, pos2)
    local deltaY = pos2.y - pos1.y
    local deltaX = pos2.x - pos1.x
    local angle = math.deg(math.atan(deltaY, deltaX))
    return (angle + 360) % 360
end

-- Finds nearest train or metro station from a position
local function FindNearestStation(pos)
    local nearestStation = nil
    local minDistance = math.huge
    for stationName, stationData in pairs(Config.TrainMetroStations) do
        local distance = GetDistanceRounded(pos, stationData.coords)
        if distance < minDistance then
            nearestStation = stationName
            minDistance = distance
        end
    end
    return nearestStation, minDistance
end

-- Checks if player heading is facing station within 90 degrees
local function IsFacingStation(playerHeading, stationHeading)
    local diff = math.abs((playerHeading - stationHeading + 180) % 360 - 180)
    return diff <= 90
end

-- Gets train/metro data for HUD display
local function GetTrainMetroData(entity)
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local nearestStation, dist = FindNearestStation(coords)

    if nearestStation and dist <= TrainDistanceLimit then
        local stationData = Config.TrainMetroStations[nearestStation]
        local northbound = stationData.nextStation.Northbound
        local southbound = stationData.nextStation.Southbound

        if northbound.s and IsFacingStation(heading, northbound.h) then
            lastNearestStation = nearestStation
            lastStationDirection = "Northbound"
        elseif southbound.s and IsFacingStation(heading, southbound.h) then
            lastNearestStation = nearestStation
            lastStationDirection = "Southbound"
        end

        return {
            atStation = true,
            currentStation = stationData.name,
            nextStation = "",
            stationDistance = 0,
            stationHeading = 0,
        }
    elseif lastNearestStation and lastStationDirection then
        local nextStationKey = Config.TrainMetroStations[lastNearestStation].nextStation[lastStationDirection]
        if nextStationKey.s then
            local stationInfo = Config.TrainMetroStations[nextStationKey]
            local stationCoords = stationInfo.coords
            local dist = GetDistanceRounded(coords, stationCoords)
            local stationHeading = CalculateBearing(coords, stationCoords)

            return {
                atStation = false,
                nextStation = stationInfo.name,
                stationDistance = Framework.Client.ConvertDistance(dist, UserSettingsData and UserSettingsData.distanceMeasurement),
                stationHeading = stationHeading,
            }
        end
    end

    return false
end

local trainDataThreadRunning = false

-- Background thread to update train metro data in the HUD
local function CreateTrainDataThread(entity)
    if trainDataThreadRunning then return end
    trainDataThreadRunning = true

    Citizen.CreateThread(function()
        while cache.vehicle do
            if not IsHudRunning() then break end
            local trainData = GetTrainMetroData(entity)
            SendNUIMessage({type = "trainMetroData", trainMetroData = trainData})
            Citizen.Wait(1000)
        end
        trainDataThreadRunning = false
    end)
end

-- Listen for player's vehicle change and create thread if train detected
lib.onCache("vehicle", function(vehicle)
    if vehicle and GetVehicleType(vehicle) == "train" and GetEntityModel(vehicle) == 868868440 then
        CreateTrainDataThread(vehicle)
    end
end)

-- Check current vehicle on load for train detection
local function CheckTrainOnLoad()
    if cache.vehicle then
        lib.onCache("vehicle", vehicle)
    end
end
