Config = {}
Config.Locale = "en"
Config.Currency = "$"
Config.NumberFormat = "en-US" -- follows [language]-[country code]

-- Integrations
Config.Framework = "QBCore" -- or "QBCore", "Qbox", "ESX"
Config.FuelSystem = "LegacyFuel" -- or "LegacyFuel", "lc_fuel", "ps-fuel", "lj-fuel", "ox_fuel", "cdn-fuel", "hyon_gas_station", "okokGasStation", "nd_fuel", "myFuel", "ti_fuel", "Renewed-Fuel", "rcore_fuel", "none"

-- Measurements
Config.SpeedMeasurement = "kph" -- or "kph"
Config.DistanceMeasurement = "meters" -- or "meters"

-- Cruise Control
Config.EnableCruiseControl = false
Config.CruiseControlKeybind = "Y"

-- Seatbelt
Config.EnableSeatbelt = true
Config.UseCustomSeatbeltIntegration = false -- Enable to use a third-party seatbelt script via Framework.Client.ToggleSeatbelt (in framework/cl-functions.lua)
Config.SeatbeltKeybind = "B"
Config.PreventExitWhileBuckled = true
Config.DisablePassengerSeatbelts = false
Config.MinSpeedMphEjectionSeatbeltOff = 20.0
Config.MinSpeedMphEjectionSeatbeltOn = 120.0
Config.DisableSeatbeltInEmergencyVehicles = false

-- Default component displays
Config.ShowMinimapOnFoot = true
Config.ShowCompassOnFoot = true
Config.ShowComponents = {
  pedAvatar = false, -- Seems to be unstable with some clients, best to leave disabled for now
  voiceOrRadio = true,
  serverId = false,
  time = false,
  job = false,
  gang = false,
  bankBalance = false,
  cashBalance = false,
  dirtyMoneyBalance = false,
  weapon = true,
  serverLogo = false -- You can enable this and then change the server-logo.png in the root folder
}

-- If ShowComponents.serverLogo & Config.AllowUsersToEditLayout are enabled, should players be able to edit the logo's visibility/position?
Config.AllowServerLogoEditing = false

-- Vehicle Control
Config.VehicleControlKeybind = ""
Config.AllowPassengersToUseVehicleControl = false -- Passengers are only able to toggle their own window, door or change seats

-- Other keybinds; set them to false to disable
Config.EngineToggleKeybind = false
Config.BoatAnchorKeybind = "J"
Config.IndicatorLeftKeybind = "LEFT"
Config.IndicatorRightKeybind = "RIGHT"
Config.IndicatorHazardsKeybind = "UP"

-- Commands
Config.OpenSettingsCommand = "hud"
Config.ToggleHudCommand = "togglehud"

-- Nearest postal
-- Credit to https://github.com/DevBlocky/nearest-postal - see license in data/nearest-postal/LICENSE
Config.ShowNearestPostal = false
Config.NearestPostalsData = "data/nearest-postal/ocrp-postals.json"

-- Learn more about configuring default settings: https://docs.jgscripts.com/hud/default-settings
Config.DefaultSettingsData = "data/default-settings.json"
Config.DefaultSettingsKvpPrefix = "hud-" -- This is really useful for essentially "resetting" everyone's currently saved settings, especially if you've added a new default-settings.json profile. You can set this to like "hud-v2-" for example so that everyone's existing data starts fresh with your new profile.
Config.AllowPlayersToEditSettings = true
Config.AllowUsersToEditLayout = true

-- Dev/debug settings
Config.UpdateRadarZoom = true -- Enable this if radar is flicking/disappearing
Config.DevDeleteAllUserSettingsOnStart = false -- Delete player existing KVP when they log in?
Config.Debug = false