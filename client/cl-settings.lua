local initialized = false
local currentPerformanceMode = nil

-- Load all HUD layout and settings data
function GetAllHudSettings()
    local defaultLayout, defaultSettings = nil, nil

    local rawData = LoadResourceFile(GetCurrentResourceName(), Config.DefaultSettingsData)
    if rawData then
        local decoded = json.decode(rawData)
        if type(decoded) == "table" then
            defaultLayout = decoded.layout
            defaultSettings = decoded.settings
        end
    else
        print(string.format("Default settings error: Could not find %s file", Config.DefaultSettingsData))
    end

    if Config.DevDeleteAllUserSettingsOnStart then
        DeleteResourceKvp(string.format("%slayout", Config.DefaultSettingsKvpPrefix or "hud-"))
        DeleteResourceKvp(string.format("%ssettings", Config.DefaultSettingsKvpPrefix or "hud-"))
    end

    local userLayout = defaultLayout or {}
    local storedLayout = json.decode(GetResourceKvpString(string.format("%slayout", Config.DefaultSettingsKvpPrefix or "hud-")) or "{}")
    if Config.AllowUsersToEditLayout and next(storedLayout) ~= nil then
        userLayout = storedLayout
    end

    local userSettings = defaultSettings or {}
    local storedSettings = json.decode(GetResourceKvpString(string.format("%ssettings", Config.DefaultSettingsKvpPrefix or "hud-")) or "{}")
    if Config.AllowPlayersToEditSettings and next(storedSettings) ~= nil then
        userSettings = storedSettings
    end

    -- Cache performance mode
    if userSettings and userSettings.performanceMode then
        currentPerformanceMode = userSettings.performanceMode
    end

    return userLayout, userSettings, currentPerformanceMode
end

-- Command to open settings menu
RegisterCommand(Config.OpenSettingsCommand or "settings", function()
    ToggleVehicleControl(false)
    DisplayRadar(false)
    TriggerScreenblurFadeIn(500)
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "showSettings" })
    initialized = true
end)

-- NUI callback to close settings
RegisterNUICallback("close-settings", function(_, cb)
    TriggerScreenblurFadeOut(500)
    DisplayRadarConditionally()
    SetNuiFocus(false, false)
    initialized = false
    cb(true)
end)

-- NUI callback to save HUD layout settings
RegisterNUICallback("save-hud-layout", function(data, cb)
    if not IsHudRunning() or not data then
        return cb(false)
    end

    local radarStyle = data.radarStyle or "rounded"
    local radarConfig = UserLayoutData["%sMinimap"]:format(radarStyle)

    local offsetX = radarConfig and radarConfig.offset and radarConfig.offset.offsetX or 0
    local offsetY = radarConfig and radarConfig.offset and radarConfig.offset.offsetY or 0
    local width = radarConfig and radarConfig.dimensions and radarConfig.dimensions.width or 0
    local height = radarConfig and radarConfig.dimensions and radarConfig.dimensions.height or 0

    local useAspectLimit = data.ignoreAspectRatioLimit or false
    local showNorthBlip = data.showNorthBlip or false

    local left, top, w, h = SetRadarMaskAndPos(
        radarStyle,
        offsetX, offsetY, width, height,
        useAspectLimit,
        showNorthBlip
    )

    SetResourceKvp(string.format("%slayout", Config.DefaultSettingsKvpPrefix or "hud-"), json.encode(data))
    UserLayoutData = data

    cb({ bounds = { left = left, top = top, width = w, height = h } })
end)

-- NUI callback to save HUD settings
RegisterNUICallback("save-hud-settings", function(data, cb)
    if not IsHudRunning() or not data then
        return cb(false)
    end

    if data.radarStyle == UserSettingsData.radarStyle and data.ignoreAspectRatioLimit == UserSettingsData.ignoreAspectRatioLimit and data.showNorthBlip == UserSettingsData.showNorthBlip then
        return cb(true)
    end

    local radarStyle = data.radarStyle or "rounded"
    local radarConfig = UserLayoutData["%sMinimap"]:format(radarStyle)

    local offsetX = radarConfig and radarConfig.offset and radarConfig.offset.offsetX or 0
    local offsetY = radarConfig and radarConfig.offset and radarConfig.offset.offsetY or 0
    local width = radarConfig and radarConfig.dimensions and radarConfig.dimensions.width or 0
    local height = radarConfig and radarConfig.dimensions and radarConfig.dimensions.height or 0

    local useAspectLimit = data.ignoreAspectRatioLimit or false
    local showNorthBlip = data.showNorthBlip or false

    local left, top, w, h = SetRadarMaskAndPos(
        radarStyle,
        offsetX, offsetY, width, height,
        useAspectLimit,
        showNorthBlip
    )

    SetResourceKvp(string.format("%ssettings", Config.DefaultSettingsKvpPrefix or "hud-"), json.encode(data))
    UserSettingsData = data

    if IsHudRunning() and data.performanceMode ~= currentPerformanceMode then
        currentPerformanceMode = data.performanceMode
        IsHudRunning = false
        Wait(100)
        StartThreads()
        if DisplayRadar then
            DisplayRadar(false)
        end
    end

    cb(true)
end)
