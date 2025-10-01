local telemetryInterval = 50.0
local lastSpeed = nil
local lastMileage = nil

-- Round distance between two 3D vectors
local function GetDistanceRounded(vec1, vec2)
    return math.round(#(vector3(vec1.x, vec1.y, vec1.z) - vector3(vec2.x, vec2.y, vec2.z)))
end

-- Calculate bearing angle between two 2D points
local function CalculateBearing(pos1, pos2)
    local deltaY = pos2.y - pos1.y
    local deltaX = pos2.x - pos1.x
    local angle = math.deg(math.atan(deltaY, deltaX))
    return (angle + 360) % 360
end

-- Get nearest train/metro station with distance
local function FindNearestStation(pos)
    local nearestStation = nil
    local minDist = math.huge
    for name, station in pairs(Config.TrainMetroStations) do
        local dist = GetDistanceRounded(pos, station.coords)
        if dist < minDist then
            nearestStation = name
            minDist = dist
        end
    end
    return nearestStation, minDist
end

-- Check if player is facing station within 90 degrees
local function IsFacingStation(playerHeading, stationHeading)
    local diff = math.abs((playerHeading - stationHeading + 180) % 360 - 180)
    return diff <= 90
end

-- Gather vehicle telemetry data for HUD display
local function GatherVehicleTelemetry()
    if not cache.vehicle or cache.vehicle == 0 then return false end
    local engineOn, highBeamsOn, headlightsOn = GetVehicleLightsState(cache.vehicle)
    local seatsCount = GetVehicleModelNumberOfSeats(GetEntityModel(cache.vehicle))
    local seatOccupied = cache.seat ~= -1

    local doorsOpen = false
    local doorsAvailable = {}
    local windowsDamaged = {}
    local windowsAvailable = {}
    local seatsOccupied = {}

    for doorIndex = 0, 6 do
        doorsOpen = doorsOpen or (GetVehicleDoorAngleRatio(cache.vehicle, doorIndex) > 0.01)
        doorsAvailable[doorIndex] = DoesVehicleHaveDoor(cache.vehicle, doorIndex)
    end

    for seatIndex = -1, seatsCount do
        local pedInSeat = GetPedInVehicleSeat(cache.vehicle, seatIndex)
        seatsOccupied[seatIndex] = (pedInSeat == cache.ped) or (not IsVehicleSeatFree(cache.vehicle, seatIndex))
    end

    for windowIndex = 0, seatsCount - 1 do
        windowsDamaged[windowIndex] = not IsVehicleWindowIntact(cache.vehicle, windowIndex)
        windowsAvailable[windowIndex] = seatOccupied and false or true
    end

    local vehicleData = {
        engineStatus = GetIsVehicleEngineRunning(cache.vehicle),
        indicatingLeft = IsVehicleIndicating(cache.vehicle, "left"),
        indicatingRight = IsVehicleIndicating(cache.vehicle, "right"),
        hazards = IsVehicleIndicating(cache.vehicle, "hazards"),
        isPassenger = seatOccupied,
        seatbelt = IsSeatbeltOn,
        cruiseControl = IsCruiseControlEnabled,
        headlights = headlightsOn,
        highBeams = highBeamsOn,
        interiorLight = IsVehicleInteriorLightOn(cache.vehicle),
        bonnetOpen = (GetVehicleDoorAngleRatio(cache.vehicle, 6) > 0.01),
        bootOpen = (GetVehicleDoorAngleRatio(cache.vehicle, 6) > 0.01),
        doors = doorsOpen,
        isConvertible = IsVehicleAConvertible(cache.vehicle, false),
        convertibleRoofRaised = (GetConvertibleRoofState(cache.vehicle) == 0),
        availableDoors = doorsAvailable,
        windows = windowsDamaged,
        availableWindows = windowsAvailable,
        seats = seatsOccupied,
        seatsCount = seatsCount,
        anchored = IsBoatAnchored(cache.vehicle),
        gear = (GetLandingGearState(cache.vehicle) == 0)
    }

    return vehicleData
end

-- Get update interval based on performance mode
local function GetTelemetryUpdateInterval()
    local mode = UserSettingsData and UserSettingsData.performanceMode
    if mode == "ultra" then return 100 end
    if mode == "performance" then return 200 end
    if mode == "lowResmon" then return 700 end
    return 300
end

-- Send telemetry data periodically to NUI
local telemetryRunning = false

local function SendTelemetryData()
    if telemetryRunning then return end
    telemetryRunning = true

    Citizen.CreateThread(function()
        while telemetryRunning do
            if not cache.vehicle or not IsHudRunning() then break end

            local vehicleType = GetVehicleType(cache.vehicle)
            local engineRunning = GetIsVehicleEngineRunning(cache.vehicle)
            local vehicleSpeed = GetEntitySpeed(cache.vehicle)
            local gear = GetVehicleCurrentGear(cache.vehicle)

            local data = GatherVehicleTelemetry()
            SendNUIMessage({ type = "vehicleTelemetryData", data = data })

            Citizen.Wait(GetTelemetryUpdateInterval())
        end
        telemetryRunning = false
    end)
end

-- Listen to vehicle cache changes to start telemetry updates
lib.onCache("vehicle", function(vehicle)
    if vehicle ~= 0 then
        SendTelemetryData()
    end
end)

-- Check vehicle on initial load
local function CheckVehicleOnLoad()
    if cache.vehicle then
        lib.onCache("vehicle", cache.vehicle)
    end
end
