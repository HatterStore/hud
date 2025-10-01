local QBCore = exports['qb-core']:GetCoreObject()

local seatbeltIsOn = false
local seatbeltDamageReduction = 0.8 -- 80% damage reduction when seatbelt is on
local seatbeltEjectSpeed = 60       -- Speed threshold for ejection without seatbelt
local currentVehicle
local seatbeltThread = nil

-- Stop the seatbelt thread
local function stopSeatbeltThread()
    if seatbeltThread then
        seatbeltThread = nil
    end
end

-- Start the main seatbelt logic thread
local function startCarThread()
    if seatbeltThread then return end

    seatbeltThread = CreateThread(function()
        while currentVehicle and IsPedInAnyVehicle(PlayerPedId()) do
            local ped = PlayerPedId()
            local vehicle = currentVehicle

            if not vehicle or not DoesEntityExist(vehicle) then
                break
            end

            local speed = GetEntitySpeed(vehicle) * 3.6

            -- Eject player if speed is high and seatbelt is off
            if speed > seatbeltEjectSpeed and not seatbeltIsOn then
                if HasEntityCollidedWithAnything(vehicle) then
                    local coords = GetEntityCoords(ped)
                    SetEntityCoords(ped, coords.x, coords.y, coords.z + 1.0)
                    SetEntityVelocity(ped, 0.0, 0.0, 5.0)
                    SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
                end
            end

            if seatbeltIsOn then
                DisableControlAction(0, 75, true) -- Disable exit vehicle
                SetPedConfigFlag(ped, 32, false)
            else
                SetPedConfigFlag(ped, 32, true)
            end

            Wait(seatbeltIsOn and 0 or 100)
        end

        seatbeltThread = nil
    end)
end

-- Keybind for seatbelt
lib.addKeybind({
    name = GetGameTimer() .. '-seatbelt',
    description = 'Fasten/Unfasten seatbelt',
    defaultKey = 'B',
    onPressed = function()
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped) or IsPauseMenuActive() then return end

        local vehicle = GetVehiclePedIsUsing(ped)
        local class = GetVehicleClass(vehicle)
        if class == 8 or class == 13 or class == 14 then return end -- Exclude bikes, cycles, etc.

        seatbeltIsOn = not seatbeltIsOn

        -- Play seatbelt sound
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5.0, seatbeltIsOn and "carbuckle" or "carunbuckle", 0.25)

        -- QBCore notification
        QBCore.Functions.Notify('You have ' .. (seatbeltIsOn and 'fastened the seatbelt' or 'unfastened the seatbelt'), 'success')

        -- OR using ox_lib notifications (uncomment if you prefer):
        -- lib.notify({
        --     title = 'Seatbelt',
        --     description = seatbeltIsOn and 'Fastened' or 'Unfastened',
        --     type = 'success'
        -- })
    end
})

-- Export for other scripts
function hasSeatbelt()
    return seatbeltIsOn
end
exports('hasSeatbelt', hasSeatbelt)

-- Vehicle cache listener
lib.onCache('vehicle', function(veh)
    local previousVehicle = currentVehicle
    currentVehicle = veh

    -- Player exited vehicle
    if not veh and previousVehicle and seatbeltIsOn then
        seatbeltIsOn = false
        stopSeatbeltThread()
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5.0, "carunbuckle", 0.25)
        QBCore.Functions.Notify('You have unfastened your seatbelt upon exiting the vehicle', 'info')
    end

    -- Player entered a new vehicle
    if veh and not previousVehicle then
        seatbeltIsOn = false
        startCarThread()
    end

    -- Vehicle removed
    if not veh and previousVehicle then
        stopSeatbeltThread()
    end
end)