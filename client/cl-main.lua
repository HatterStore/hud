-- Ensure Locales table exists
Locales = Locales or {}

-- Set the Locale based on Config
Locale = Locales[Config.Locale or "en"] or {}

-- Keep track of HUD state
local isHudRunning = false

-- Global getter for other scripts
function IsHudRunning()
    return isHudRunning
end

local debugEnabled = Config.Debug or false
local isHudRunning = false
UserSettingsData = {}
UserLayoutData = {}

-- Debug print helper
function DebugPrint(message)
  if debugEnabled then
    print(string.format("[JG HUD Debug]: %s", message))
  end
end

-- Get vehicle type string: land, sea, air, train, bicycle
function GetVehicleType(entity)
  if not DoesEntityExist(entity) or not IsEntityAVehicle(entity) then
    return nil
  end

  local model = GetEntityModel(entity)

  if IsThisModelABoat(model) or IsThisModelAJetski(model) then
    return "sea"
  elseif IsThisModelAHeli(model) or IsThisModelAPlane(model) then
    return "air"
  elseif IsThisModelATrain(model) then
    return "train"
  elseif IsThisModelABicycle(model) then
    return "bicycle"
  else
    return "land"
  end
end

-- Check if vehicle is electric
function IsVehicleElectric(entity)
  local build = GetGameBuildNumber()
  if build >= 3258 then
    return Citizen.InvokeNative(2290933623539066425, GetEntityModel(entity)) == 1
  else
    return lib.table.contains(Config.ElectricVehicles, GetEntityArchetypeName(entity))
  end
end

-- Display radar conditionally based on settings and state
function DisplayRadarConditionally()
  local shouldShow = Config.ShowMinimapOnFoot and UserSettingsData and UserSettingsData.showMinimapOnFoot
  DisplayRadar(shouldShow or (cache and cache ~= false))
  return shouldShow
end

local hudLoopActive = false

-- Start HUD loop watching pause menu state and updating HUD
function StartHudLoop()
  if hudLoopActive then return end
  hudLoopActive = true
  local wasPaused = IsPauseMenuActive()

  Citizen.CreateThread(function()
    while IsHudRunning() do
      Citizen.Wait(1000)
      local isPaused = IsPauseMenuActive()
      if wasPaused ~= isPaused then
        wasPaused = isPaused
        ToggleHud(not isPaused) -- Your HUD toggle function needed here
      end
    end
    hudLoopActive = false
  end)
end

-- Placeholder for HUD toggle function (implement as needed)
function ToggleHud(enabled)
  -- Implement HUD show/hide logic here
end
