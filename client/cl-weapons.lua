-- Map weapon names config to hash lookup table
local weaponNamesByHash = {}
for weaponName in pairs(Config.WeaponNames or {}) do
    weaponNamesByHash[joaat(weaponName)] = weaponName
end

-- Get weapon data including hash, name, ammo counts
function GetWeaponData(weaponHash)
    if not (Config.ShowComponents and Config.ShowComponents.weapon) then
        return false
    end

    if not weaponHash then
        weaponHash = cache.weapon
    end

    if not weaponHash then
        return false
    end

    local weaponName = weaponNamesByHash[weaponHash]
    if Config.WeaponNames then
        weaponName = Config.WeaponNames[weaponName]
    end

    local inVehicle, vehicleWeaponHash = GetCurrentPedVehicleWeapon(cache.ped)
    if inVehicle then
        weaponName = "Vehicle Weapon"
    end

    local ammo
    if inVehicle then
        local restrictedAmmo = GetVehicleWeaponRestrictedAmmo(cache.vehicle, vehicleWeaponHash)
        if restrictedAmmo then
            ammo = restrictedAmmo
        end
    end

    if not ammo then
        ammo = GetAmmoInPedWeapon(cache.ped, weaponHash)
    end

    local clip, currentlyReloading = GetAmmoInClip(cache.ped, weaponHash)

    return {
        weaponHash = weaponName,
        weaponName = weaponName,
        reserveAmmo = ammo - clip,
        clipAmmo = clip
    }
end

-- Send weapon data to NUI
function SendWeaponData(weaponHash)
    SendNUIMessage({
        type = "weaponData",
        weaponData = GetWeaponData(weaponHash)
    })
end

local weaponUpdateThreadRunning = false

-- Thread to repeatedly send weapon data updates while HUD running
function CreateWeaponUpdateThread()
    if weaponUpdateThreadRunning or not (Config.ShowComponents and Config.ShowComponents.weapon) then
        return
    end

    if not cache.ped or not cache.weapon then
        return
    end

    weaponUpdateThreadRunning = true

    Citizen.CreateThread(function()
        while cache.ped and cache.weapon and IsHudRunning() do
            SendWeaponData(cache.weapon)
            Citizen.Wait(1000)
        end
        weaponUpdateThreadRunning = false
    end)
end

-- Initialize weapon HUD updates on load
function CheckWeaponOnLoad()
    if (Config.ShowComponents and Config.ShowComponents.weapon) and cache.weapon then
        SendWeaponData(cache.weapon)
        CreateWeaponUpdateThread()
    end
end

-- Setup cache listener and gunshot event handler to update weapon data
if Config.ShowComponents and Config.ShowComponents.weapon then
    lib.onCache("weapon", function(weapon)
        SendWeaponData(weapon)
        CreateWeaponUpdateThread()
    end)

    AddEventHandler("CEventGunShot", function(attacker, weaponOwner)
        if weaponOwner ~= cache.ped then return end
        SendWeaponData(cache.weapon)
        CreateWeaponUpdateThread()
    end)
end
