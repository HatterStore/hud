-- Seatbelt state
IsSeatbeltOn = true
local seatbeltThreadRunning = false

-- Check if vehicle class supports seatbelt
local function IsSeatbeltSupported(vehicle)
    if not Config.EnableSeatbelt then
        return false
    end

    if not vehicle or not DoesEntityExist(vehicle) then
        return false
    end

    local vehicleClass = GetVehicleClass(vehicle)
    local supportedClasses = {
        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
        [6] = true, [7] = true, [9] = true, [10] = true, [11] = true, [12] = true,
        [17] = true, [18] = true, [19] = true, [20] = true,
    }
    
    return supportedClasses[vehicleClass] == true
end

-- Determine if seatbelt should be enabled for current passenger
local function ShouldEnableSeatbelt(vehicle)
    if not Config.EnableSeatbelt or not vehicle then
        return false
    end

    if not IsSeatbeltSupported(vehicle) then
        return false
    end

    if Config.DisablePassengerSeatbelts and cache.seat ~= -1 then
        return false
    end

    if Config.DisableSeatbeltInEmergencyVehicles then
        local vehicleClass = GetVehicleClass(vehicle)
        if vehicleClass == 18 then -- Emergency vehicle class
            return false
        end
    end

    return true
end

-- Main seatbelt enforcement thread which disables exiting when buckled
local function SeatbeltThread(vehicle)
    if seatbeltThreadRunning then return end
    seatbeltThreadRunning = true

    Citizen.CreateThread(function()
        while cache.vehicle do
            if ShouldEnableSeatbelt(vehicle) then
                if Config.PreventExitWhileBuckled and IsSeatbeltOn then
                    DisableControlAction(0, 75, true)  -- Disable exit vehicle control
                    DisableControlAction(27, 75, true) -- Disable exit vehicle control for alternate input
                end
            end
            Citizen.Wait(0)
        end
        seatbeltThreadRunning = false
    end)
end

-- Toggle seatbelt state
function ToggleSeatbelt(vehicle)
    if not vehicle or not ShouldEnableSeatbelt(vehicle) then
        IsSeatbeltOn = true
        return
    end

    IsSeatbeltOn = false

    SetFlyThroughWindscreenParams(
        Config.MinSpeedMphEjectionSeatbeltOff / 2.237,  -- Convert mph to m/s
        1.0, 17.0, 10.0
    )
    SetPedConfigFlag(cache.ped, 32, true) -- Enable flag (example)

    SeatbeltThread(vehicle)
end

-- Toggle seatbelt state and sync to player state
function ToggleSeatbeltCommand(vehicle)
    if not vehicle or not ShouldEnableSeatbelt(vehicle) then
        return false
    end

    IsSeatbeltOn = not IsSeatbeltOn
    LocalPlayer.state:set("seatbelt", IsSeatbeltOn)

    local speedParam = IsSeatbeltOn and
        (Config.MinSpeedMphEjectionSeatbeltOn or 0) / 2.237 or -- convert mph to m/s
        Config.MinSpeedMphEjectionSeatbeltOff / 2.237

    SetFlyThroughWindscreenParams(speedParam, 1.0, 17.0, 10.0)
    return IsSeatbeltOn
end

-- Register toggle command and keybinding
if Config.EnableSeatbelt then
    if Config.SeatbeltKeybind then
        RegisterCommand("toggle_seatbelt", function()
            ToggleSeatbeltCommand(cache.vehicle)
        end, false)

        RegisterKeyMapping(
            "toggle_seatbelt",
            "Toggle vehicle seatbelt",
            "keyboard",
            Config.SeatbeltKeybind or "B"
        )
    end

    -- Initialize with current vehicle state
    lib.onCache("vehicle", function(vehicle)
        if vehicle then
            ToggleSeatbelt(vehicle)
        end
    end)

    Citizen.CreateThread(function()
        if cache.vehicle then
            ToggleSeatbelt(cache.vehicle)
        end
    end)
end
