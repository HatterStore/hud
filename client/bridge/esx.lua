if not hasResource('es_extended') then return end

lib.print.info('ESX Bridge Ready')

local ESX = exports.es_extended:getSharedObject()
local PlayerData, isLoggedIn = {
    job = {
        label = '',
        grade = { name = '' },
        metadata = { hunger = 0, thirst = 0 }
    },
    money = {
        cash = 0,
        bank = 0,
    },
    metadata = {
        hunger = 0,
        thirst = 0
    }
}, false

-- Funktion zum Abfragen von Hunger/Durst Status
function getStatus(s)
    local p = promise.new()
    TriggerEvent('esx_status:getStatus', s, function(o)
        if o then
            p:resolve(o.getPercent())
        else
            p:resolve(0)
        end
    end)
    return Citizen.Await(p)
end

-- Spieler geladen
RegisterNetEvent('esx:playerLoaded', function(pData, isNew)
    if not pData then return end

    -- Job
    if pData.job then
        PlayerData.job = {
            label = pData.job.label or '',
            grade = {
                name = pData.job.grade_label or ''
            }
        }
    end

    -- Accounts
    if pData.accounts and type(pData.accounts) == 'table' then
        for i = 1, #pData.accounts do
            local accName = pData.accounts[i].name == 'money' and 'cash' or pData.accounts[i].name
            PlayerData.money[accName] = pData.accounts[i].money or 0
        end
    end

    -- Metadata
    PlayerData.metadata = PlayerData.metadata or {}
    PlayerData.metadata.hunger = getStatus('hunger') or 0
    PlayerData.metadata.thirst = getStatus('thirst') or 0
end)

-- Status Update (Tick)
RegisterNetEvent('esx_status:onTick', function(s)
    if not s then return end
    PlayerData.metadata = PlayerData.metadata or {}
    for i = 1, #s do
        if PlayerData.metadata[s[i].name] ~= nil then
            PlayerData.metadata[s[i].name] = s[i].percent
        end
    end
end)

-- Hole Player Data
function GetPlayerData()
    local pData = PlayerData

    if ESX.PlayerData then
        -- Accounts
        if ESX.PlayerData.accounts and type(ESX.PlayerData.accounts) == 'table' then
            for i = 1, #ESX.PlayerData.accounts do
                local accName = ESX.PlayerData.accounts[i].name == 'money' and 'cash' or ESX.PlayerData.accounts[i].name
                pData.money[accName] = ESX.PlayerData.accounts[i].money or 0
            end
        end

        -- Metadata
        pData.metadata = pData.metadata or {}
        pData.metadata.hunger = getStatus('hunger') or 0
        pData.metadata.thirst = getStatus('thirst') or 0

        -- Job
        if ESX.PlayerData.job then
            pData.job = {
                label = ESX.PlayerData.job.label or '',
                grade = {
                    name = ESX.PlayerData.job.grade_label or ''
                }
            }
        end
    end

    return pData
end

-- Check ob Spieler geladen ist
function IsPlayerLoaded()
    return ESX.IsPlayerLoaded()
end