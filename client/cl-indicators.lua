-- Return vehicle indicator state as a table: {left, right}
function GetIndicatingState(vehicle)
    if not vehicle or vehicle == 0 then
        return {false, false}
    end

    local state = Entity(vehicle).state
    local indicate = state and state.indicate

    if not indicate then
        return {false, false}
    end

    return indicate
end

-- Check if vehicle is indicating a specific direction ("left", "right", or "hazards")
function IsVehicleIndicating(vehicle, indicatorType)
    if not vehicle or vehicle == 0 then
        return false
    end

    local indicate = Entity(vehicle).state.indicate
    if not indicate then
        return false
    end

    if indicate[1] and indicate[2] and indicatorType == "hazards" then
        return true
    elseif indicate[1] and not indicate[2] and indicatorType == "right" then
        return true
    elseif not indicate[1] and indicate[2] and indicatorType == "left" then
        return true
    end

    return false
end

-- Toggle vehicle indicators in the given direction ("left", "right", "hazards")
function Indicate(direction)
    if not cache.vehicle or cache.seat ~= -1 then
        return false
    end

    if IsPauseMenuActive() then
        return false
    end

    local newState

    if direction == "left" then
        if not IsVehicleIndicating(cache.vehicle, "left") then
            newState = {false, true} -- left indicator on
        end
    elseif direction == "right" then
        if not IsVehicleIndicating(cache.vehicle, "right") then
            newState = {true, false} -- right indicator on
        end
    elseif direction == "hazards" then
        if not IsVehicleIndicating(cache.vehicle, "hazards") then
            newState = {true, true} -- both indicators on (hazards)
        end
    else
        newState = {false, false} -- indicators off
    end

    if newState then
        -- Set the indicator state in the entity state bag and sync across clients
        Entity(cache.vehicle).state:set("indicate", newState, true)
    end
end

-- Listen for indicator state changes and update vehicle lights and UI accordingly
AddStateBagChangeHandler("indicate", "", function(bagName, key, value)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 then return end

    for index, state in ipairs(value) do
        SetVehicleIndicatorLights(vehicle, index - 1, state)
    end

    SendNUIMessage({
        type = "vehicleStatusUpdate",
        data = {indicators = value}
    })
end)

-- Register commands and key mappings based on configuration
if Config.IndicatorLeftKeybind then
    RegisterCommand("indicate_left", function()
        Indicate("left")
    end)
    RegisterKeyMapping("indicate_left", "Vehicle indicate left", "keyboard", Config.IndicatorLeftKeybind or "LEFT")
end

if Config.IndicatorRightKeybind then
    RegisterCommand("indicate_right", function()
        Indicate("right")
    end)
    RegisterKeyMapping("indicate_right", "Vehicle indicate right", "keyboard", Config.IndicatorRightKeybind or "RIGHT")
end

if Config.IndicatorHazardsKeybind then
    RegisterCommand("hazards", function()
        Indicate("hazards")
    end)
    RegisterKeyMapping("hazards", "Vehicle hazards", "keyboard", Config.IndicatorHazardsKeybind or "UP")
end
