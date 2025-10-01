-- Minimap and mask offsets/configuration for different styles
local MinimapOffsets = {
    square = {
        minimap = {0.0, 0.0, 0.1425, 0.188888},
        minimap_mask = {0.02, 0.032, 0.111, 0.159},
        minimap_blur = {-0.0305, 0.04, 0.27, 0.272}
    },
    rounded = {
        minimap = {0.0, 0.0, 0.1425, 0.188888},
        minimap_mask = {0.02, 0.032, 0.111, 0.159},
        minimap_blur = {-0.0305, 0.04, 0.27, 0.272}
    },
    circular = {
        minimap = {-0.008, 0.005, 0.12, 0.202},
        minimap_mask = {0.02, 0.032, 0.111, 0.159},
        minimap_blur = {-0.021, 0.04, 0.192, 0.272}
    }
}

-- Calculate minimap position offsets based on screen resolution and aspect ratio
local function GetMinimapOffsets(useAspectCorrection)
    local resX, resY = GetActualScreenResolution()
    local offsetX, offsetY = 0.0, -0.05

    if useAspectCorrection then
        local aspectRatio = GetAspectRatio(false)
        local targetRatio = 1.7777777777777777 -- 16:9
        if aspectRatio > targetRatio then
            offsetX = (targetRatio - aspectRatio) / 3.6
        end
    end

    if resY < 1400 then offsetY = -0.06 end
    if resY < 1240 then offsetY = -0.07 end
    if resY < 1050 then offsetY = -0.09 end
    if resY < 950 then offsetY = -0.09 end
    if resY < 850 then offsetY = -0.10 end
    if resY < 750 then offsetY = -0.11 end
    if resY < 650 then offsetY = -0.14 end

    return offsetX, offsetY
end

-- Set radar mask and position according to style with scaling and cropping parameters
local function SetRadarMaskAndPosition(style, x, y, width, height, scale, alpha, useAspectCorrection)
    local offsetX, offsetY, scaleFactor = 1.0, 0.0, 1.0
    offsetX, offsetY = GetMinimapOffsets(useAspectCorrection)
    local screenW, screenH = GetActualScreenResolution()
    local aspectRatio = GetAspectRatio(false)
    local baseAspect = 1.7777777777777777 -- 16:9

    if scale then
        scaleFactor = scale / width
    end

    if x then
        offsetX = offsetX + (x / screenW) * (aspectRatio / baseAspect)
    end

    if y then
        local baseHeight = scale or width
        offsetY = offsetY + (baseHeight - width + y) / screenH
    end

    for componentName, dimensions in pairs(MinimapOffsets[style]) do
        SetMinimapComponentPosition(
            componentName, "L", "B",
            dimensions[1] * scaleFactor + offsetX,
            dimensions[2] * scaleFactor + offsetY,
            dimensions[3] * scaleFactor,
            dimensions[4] * scaleFactor
        )
    end

    SetBlipAlpha(GetNorthRadarBlip(), alpha and 255 or 0)
    SetMinimapClipType(style == "circular" and 1 or 0)
    SetBigmapActive(true, false)
    Wait(1)
    SetBigmapActive(false, false)

    return offsetX, offsetY, scaleFactor, screenH / 5.5
end

-- Create radar thread for setting up and maintaining radar UI
local radarThreadCreated = false

function CreateRadarThread()
    if radarThreadCreated then return end
    radarThreadCreated = true

    local minimapScaleform = lib.requestScaleformMovie("minimap")
    if not minimapScaleform then
        print("Could not load minimap scaleform movie")
        return
    end

    SetBigmapActive(true, false)
    Wait(1)
    SetBigmapActive(false, false)

    Citizen.CreateThread(function()
        while IsHudRunning() do
            BeginScaleformMovieMethod(minimapScaleform, "SETUP_HEALTH_ARMOUR")
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
            SetBigmapActive(false, false)

            if Config.UpdateRadarZoom then
                SetRadarZoom(1100)
            end

            Wait(250)
        end
        radarThreadCreated = false
    end)
end

-- Create a persistent thread to hide specified HUD components as configured
local hudComponentsHidden = false

function CreateHideHudComponentsThread()
    if not Config.HideBaseGameHudComponents then return end
    if hudComponentsHidden then return end
    hudComponentsHidden = true

    Citizen.CreateThread(function()
        while IsHudRunning() do
            for _, componentId in ipairs(Config.HideBaseGameHudComponents or {}) do
                HideHudComponentThisFrame(componentId)
            end
            Wait(0)
        end
        hudComponentsHidden = false
    end)
end
