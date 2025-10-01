-- =============================
-- Vehicle Controls Script
-- =============================

-- Initialize QBCore Framework
local QBCore = exports['qb-core']:GetCoreObject()

-- State variables
local boatAnchored = false
local controlLoopActive = false
local seatbeltIsOn = false
local lastVehicle = nil
local seatbeltThread = false

-- =============================
-- Helper Functions
-- =============================

-- Returns update interval for vehicle controls loop
local function GetUpdateInterval()
    return 50 -- milliseconds
end

-- Toggle boat anchor
local function ToggleBoatAnchor(vehicle)
    if not vehicle or vehicle == 0 then return end
    if cache.seat ~= -1 then return end
    if GetVehicleType(vehicle) ~= "sea" then return end

    local speed = GetEntitySpeed(vehicle) * 2.23694 -- m/s -> mph
    if speed > 5 then return end

    SetBoatRemainsAnchoredWhilePlayerIsDriver(vehicle, true)
    local anchored = IsBoatAnchored(vehicle)
    SetBoatAnchor(vehicle, not anchored)
end

-- Toggle vehicle engine
local function ToggleEngine(vehicle)
    if not vehicle or vehicle == 0 then return end
    if cache.seat ~= -1 then return end

    local engineRunning = GetIsVehicleEngineRunning(vehicle)
    
    -- Use QBCore's vehicle functions or native FiveM functions
    if QBCore and QBCore.Functions and QBCore.Functions.SetVehicleProperties then
        -- QBCore method
        SetVehicleEngineOn(vehicle, not engineRunning, false, true)
    else
        -- Direct native method
        SetVehicleEngineOn(vehicle, not engineRunning, false, true)
    end
end

-- Toggle seatbelt
local function ToggleSeatbelt()
    seatbeltIsOn = not seatbeltIsOn

    -- Play seatbelt sound
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5.0, seatbeltIsOn and "carbuckle" or "carunbuckle", 0.25)

    -- QBCore notification instead of ESX
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify('You have ' .. (seatbeltIsOn and 'fastened the seatbelt' or 'unfastened the seatbelt'), 'primary')
    else
        -- Fallback to ESX if QBCore notification doesn't work
        local ESX = exports['es_extended']:getSharedObject()
        ESX.ShowNotification('You have ' .. (seatbeltIsOn and 'fastened the seatbelt' or 'unfastened the seatbelt'))
    end

    -- Start or stop seatbelt protection thread
    if seatbeltIsOn then
        StartSeatbeltProtection()
    else
        StopSeatbeltProtection()
    end
end

-- Seatbelt protection system
local function StartSeatbeltProtection()
    if seatbeltThread then return end
    seatbeltThread = true
    
    Citizen.CreateThread(function()
        while seatbeltThread and cache.vehicle do
            local ped = cache.ped
            local vehicle = cache.vehicle
            
            if vehicle and vehicle ~= 0 and seatbeltIsOn then
                -- Prevent player from being ejected during crashes
                DisableControlAction(0, 75, true) -- Disable exit vehicle key
                SetPedCanBeKnockedOffVehicle(ped, 1) -- Allow knockoff but we'll handle it
                
                -- Check for high impact collisions
                if HasEntityCollidedWithAnything(vehicle) then
                    local velocity = GetEntityVelocity(vehicle)
                    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2) * 3.6 -- Convert to km/h
                    
                    if speed > 50 then -- High speed collision
                        -- Apply damage but keep player in vehicle
                        local health = GetEntityHealth(ped)
                        local newHealth = math.max(health - math.random(5, 15), 10) -- Reduce health but don't kill
                        SetEntityHealth(ped, newHealth)
                        
                        -- Shake screen effect for impact
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
                        
                        -- Optional: Blood effect
                        SetPedMinorInjury(ped, true, true)
                    end
                    
                    -- Always keep seatbelt on during collision
                    if not seatbeltIsOn then
                        seatbeltIsOn = true
                    end
                end
                
                -- Ensure player stays in seat
                if not IsPedInVehicle(ped, vehicle, false) and seatbeltIsOn then
                    TaskWarpPedIntoVehicle(ped, vehicle, cache.seat or -1)
                end
            else
                break
            end
            
            Citizen.Wait(10) -- Run frequently for collision detection
        end
        seatbeltThread = false
    end)
end

-- Stop seatbelt protection
local function StopSeatbeltProtection()
    seatbeltThread = false
    -- Re-enable normal vehicle exit
    EnableControlAction(0, 75, true)
end

-- Toggle cruise control
local function ToggleCruiseControl(vehicle)
    if not vehicle or vehicle == 0 then return end
    cache.cruiseControl = not (cache.cruiseControl or false)
    if cache.cruiseControl then
        cache.cruiseSpeed = GetEntitySpeed(vehicle)
    else
        cache.cruiseSpeed = nil
    end
end

-- Toggle indicators (simplified)
local function Indicate(direction)
    if not cache.vehicle or cache.vehicle == 0 then return end
    -- direction = "left", "right", or "hazard"
    -- Implement your indicator logic here
end

-- =============================
-- Gather Vehicle State
-- =============================
local function GatherVehicleControlState()
    if not cache.vehicle or cache.vehicle == 0 then return nil end

    local vehicle = cache.vehicle
    local speed = GetEntitySpeed(vehicle) * 2.23694 -- m/s -> mph
    local engineOn = GetIsVehicleEngineRunning(vehicle)
    local lightsOn, highBeamsOn = GetVehicleLightsState(vehicle)
    local gearState = GetLandingGearState(vehicle)
    local roofState = GetConvertibleRoofState(vehicle) == 0
    local interiorLight = IsVehicleInteriorLightOn(vehicle)
    local anchored = GetVehicleType(vehicle) == "sea" and IsBoatAnchored(vehicle) or false

    return {
        speed = speed,
        engineOn = engineOn,
        lightsOn = lightsOn,
        highBeamsOn = highBeamsOn,
        seatbeltOn = seatbeltIsOn,
        cruiseControlOn = cache.cruiseControl or false,
        gearState = gearState,
        roofOpen = roofState,
        interiorLight = interiorLight,
        anchored = anchored
    }
end

-- =============================
-- Handle Vehicle Actions
-- =============================
local function HandleVehicleControl(action, value)
    if not cache.vehicle or cache.vehicle == 0 then return end
    local isPassenger = cache.seat ~= -1

    if action == "TOGGLE_ENGINE" and not isPassenger then
        ToggleEngine(cache.vehicle)
    elseif action == "INDICATE" and not isPassenger then
        Indicate(value)
    elseif action == "TOGGLE_SEATBELT" then
        ToggleSeatbelt()
    elseif action == "TOGGLE_CRUISE_CONTROL" and not isPassenger then
        ToggleCruiseControl(cache.vehicle)
    elseif action == "TOGGLE_HEADLIGHTS" and not isPassenger then
        local lightsOn, highBeamsOn = GetVehicleLightsState(cache.vehicle)
        SetVehicleLights(cache.vehicle, (lightsOn or highBeamsOn) and 3 or 4)
    elseif action == "TOGGLE_INTERIOR_LIGHT" and not isPassenger then
        local interiorLightOn = IsVehicleInteriorLightOn(cache.vehicle)
        SetVehicleInteriorlight(cache.vehicle, not interiorLightOn)
    elseif action == "TOGGLE_VEHICLE_DOOR" then
        if isPassenger and cache.seat ~= value - 1 then return end
        local isDoorOpen = GetVehicleDoorAngleRatio(cache.vehicle, value) > 0.01
        if isDoorOpen then
            SetVehicleDoorShut(cache.vehicle, value, false)
        else
            SetVehicleDoorOpen(cache.vehicle, value, false, false)
        end
    elseif action == "TOGGLE_VEHICLE_WINDOW" then
        if isPassenger and cache.seat ~= value - 1 then return end
        if IsVehicleWindowIntact(cache.vehicle, value) then
            RollDownWindow(cache.vehicle, value)
        else
            RollUpWindow(cache.vehicle, value)
        end
    elseif action == "SET_VEHICLE_SEAT" then
        TaskWarpPedIntoVehicle(cache.ped, cache.vehicle, value)
    elseif action == "TOGGLE_ANCHOR" and not isPassenger then
        ToggleBoatAnchor(cache.vehicle)
    elseif action == "TOGGLE_GEAR" and not isPassenger then
        local gearState = GetLandingGearState(cache.vehicle)
        ControlLandingGear(cache.vehicle, gearState == 0 and 1 or 2)
    elseif action == "TOGGLE_CONVERTIBLE_ROOF" and not isPassenger then
        local roofState = GetConvertibleRoofState(cache.vehicle) == 0
        if roofState then
            LowerConvertibleRoof(cache.vehicle, false)
        else
            RaiseConvertibleRoof(cache.vehicle, false)
        end
    end
end

-- =============================
-- Vehicle Control Loop
-- =============================
local function StartVehicleControlLoop()
    if controlLoopActive then return end
    controlLoopActive = true

    Citizen.CreateThread(function()
        while controlLoopActive and cache.vehicle do
            local stateData = GatherVehicleControlState()
            if not stateData then
                ToggleVehicleControl(false)
                break
            end
            SendNUIMessage({ type = "vehicleControlsStateData", data = stateData })
            Citizen.Wait(GetUpdateInterval())
        end
        controlLoopActive = false
    end)
end

-- =============================
-- Toggle Vehicle Control UI
-- =============================
function ToggleVehicleControl(enable)
    if enable == nil then enable = false end
    if enable then
        if IsPauseMenuActive() then return end
        if not cache.vehicle then return end
        if cache.seat ~= -1 and not Config.AllowPassengersToUseVehicleControl then return end

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        SendNUIMessage({ type = "showVehicleControls" })
        StartVehicleControlLoop()
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ type = "closeVehicleControls" })
    end
end

-- =============================
-- Commands & NUI Callbacks
-- =============================
RegisterCommand("open_vehicle_controls", function()
    ToggleVehicleControl(true)
end, false)

RegisterKeyMapping("open_vehicle_controls", "Open vehicle control menu", "keyboard", Config.VehicleControlKeybind or "F6")

RegisterCommand("anchor_boat", function()
    ToggleBoatAnchor(cache.vehicle)
end, false)

RegisterKeyMapping("anchor_boat", "Anchor boat", "keyboard", Config.BoatAnchorKeybind or "J")

RegisterCommand("toggle_engine", function()
    ToggleEngine(cache.vehicle)
end, false)

RegisterKeyMapping("toggle_engine", "Toggle vehicle engine", "keyboard", Config.EngineToggleKeybind or "G")

RegisterNUICallback("vehicleControlAction", function(data, cb)
    if not data or not data.action then return cb({ error = true }) end
    if not cache.vehicle or cache.vehicle == 0 then return cb({ error = true }) end

    HandleVehicleControl(data.action, data.value)
    cb(true)
end)

RegisterNUICallback("closeVehicleControls", function(_, cb)
    ToggleVehicleControl(false)
    cb(true)
end)

-- =============================
-- Exports & Events
-- =============================
exports("toggleVehicleControl", ToggleVehicleControl)

RegisterNetEvent("jg-hud:client:toggle-vehicle-control")
AddEventHandler("jg-hud:client:toggle-vehicle-control", function(vehicle)
    ToggleVehicleControl(vehicle)
end)

-- Handle vehicle changes and cleanup
lib.onCache("vehicle", function(vehicle)
    if vehicle == 0 then
        -- Player exited vehicle, reset seatbelt
        seatbeltIsOn = false
        StopSeatbeltProtection()
        lastVehicle = nil
    else
        lastVehicle = vehicle
    end
end)

-- Cleanup when player is no longer in vehicle
Citizen.CreateThread(function()
    while true do
        if not cache.vehicle or cache.vehicle == 0 then
            if seatbeltIsOn then
                seatbeltIsOn = false
                StopSeatbeltProtection()
            end
        end
        Citizen.Wait(1000)
    end
end)