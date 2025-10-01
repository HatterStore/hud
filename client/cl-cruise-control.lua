-- Cruise Control State Variable
IsCruiseControlEnabled = false
local cruiseSpeed = 0.0

-- Check if vehicle is going straight relative to its velocity vector
local function isVehicleGoingStraight(vehicle, angleThreshold)
    angleThreshold = angleThreshold or 0.01

    local forwardVec = GetEntityForwardVector(vehicle)
    local velocity = GetEntityVelocity(vehicle)

    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    if speed < 1.0 then
        return false, 0.0
    end

    local normalizedVelocity = {
        x = velocity.x / speed,
        y = velocity.y / speed,
        z = velocity.z / speed,
    }

    local dotProduct = forwardVec.x * normalizedVelocity.x +
                       forwardVec.y * normalizedVelocity.y +
                       forwardVec.z * normalizedVelocity.z

    local clampedDot = math.max(-1, math.min(1, dotProduct))
    local angleRad = math.acos(clampedDot)
    local angleDeg = math.deg(angleRad)
    
    local exceeded = angleDeg > angleThreshold * 180
    return exceeded, angleDeg
end

-- Check if certain vehicle controls are pressed (accelerate/brake)
local function isAccOrBrakePressed()
    if IsControlPressed(2, 76) or IsControlPressed(2, 63) or IsControlPressed(2, 64) then
        return true
    end
    return false
end

-- Toggle cruise control on or off for a given vehicle and seat
function ToggleCruiseControl(vehicle, seat)
    if not Config.EnableCruiseControl then return end

    if IsCruiseControlEnabled then
        IsCruiseControlEnabled = false
        return
    end

    if not vehicle and seat ~= -1 then return end

    if GetVehicleType(vehicle) ~= "land" then return end

    local speed = GetEntitySpeed(vehicle)
    if speed < 1.0 then return end

    if not GetIsVehicleEngineRunning(vehicle) then return end

    if isVehicleGoingStraight(vehicle) then return end

    if isAccOrBrakePressed() then return end

    IsCruiseControlEnabled = true
    cruiseSpeed = speed

    CreateThread(function()
        while true do
            if not cache.vehicle or not IsCruiseControlEnabled or not IsHudRunning or not GetIsVehicleEngineRunning(vehicle) then
                break
            end
            
            local currentSpeed = GetEntitySpeed(cache.vehicle)
            local pressed = isAccOrBrakePressed()

            if not pressed then
                if IsVehicleOnAllWheels(cache.vehicle) and currentSpeed < cruiseSpeed - 1.5 then
                    SetVehicleForwardSpeed(cache.vehicle, cruiseSpeed)
                end
            else
                IsCruiseControlEnabled = false
                Wait(500)
                break
            end

            if IsControlJustPressed(1, 246) then
                cruiseSpeed = GetEntitySpeed(cache.vehicle)
            end

            if IsControlJustPressed(2, 72) then
                IsCruiseControlEnabled = false
                Wait(500)
                break
            end

            Wait(50)
        end
    end)
end

-- Register the command and keybind to toggle cruise control
if Config.EnableCruiseControl and Config.CruiseControlKeybind then
    RegisterCommand("toggle_cruise", function()
        ToggleCruiseControl(cache.vehicle, cache.seat)
    end, false)

    RegisterKeyMapping(
        "toggle_cruise", 
        "Toggle cruise control", 
        "keyboard", 
        Config.CruiseControlKeybind or "J"
    )
end
