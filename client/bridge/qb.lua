local availableCores = { 'qb-core', 'qbx_core' }
local hasFramework

-- check welches Framework geladen ist
for i = 1, #availableCores, 1 do
    if hasResource(availableCores[i]) then
        hasFramework = availableCores[i]
        break
    end
end

if not hasFramework then return end

lib.print.info('QBCore Bridge Ready (' .. hasFramework .. ')')

-- lade je nach Framework das Core-Object
local QBCore
if hasFramework == 'qb-core' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif hasFramework == 'qbx_core' then
    QBCore = exports['qbx_core']:GetCoreObject()
end

local PlayerData, isLoggedIn = {}, false

-- Spieler lädt ein
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
end)

-- Spieler entlädt
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
end)

-- Job Update
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Gang Update
RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
    PlayerData.gang = GangInfo
end)

-- Player Data Update
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- Needs Update (Hunger/Thirst)
RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    local meta = PlayerData.metadata or {}
    meta.hunger = newHunger or 0
    meta.thirst = newThirst or 0

    PlayerData.metadata = meta
end)

-- Globale Getter
_G.GetPlayerData = function()
    return QBCore.Functions.GetPlayerData()
end

_G.IsPlayerLoaded = function()
    return LocalPlayer.state.isLoggedIn
end