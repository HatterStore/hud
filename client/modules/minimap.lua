local Menu, mapUp, mapWidth = { isToggleMapShapeChecked = 'square' }, -0.02, -0.02

RegisterNetEvent('hud:client:LoadMap', function()
    Wait(50)
    local defaultAR, rx, ry = 1920 / 1080, GetActiveScreenResolution()
    local offset = (rx / ry > defaultAR) and ((defaultAR - rx / ry) / 3.6) - 0.008 or 0
    local dict = Menu.isToggleMapShapeChecked == 'square' and 'squaremap' or 'circlemap'
    local clip = Menu.isToggleMapShapeChecked == 'square' and 0 or 1
    RequestStreamedTextureDict(dict)
    while not HasStreamedTextureDictLoaded(dict) do Wait(150) end
    SetMinimapClipType(clip)
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', dict, 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', dict, 'radarmasksm')

    local function adjust(w, h)
        return w + mapWidth, h
    end

    local p = Menu.isToggleMapShapeChecked == 'square' and {
        { 0 + offset,     -0.047 + mapUp, adjust(0.1638, 0.183) },
        { 0 + offset,     0 + mapUp,      adjust(0.128, 0.20) },
        { -0.01 + offset, 0.025 + mapUp,  adjust(0.262, 0.300) }
    } or {
        { -0.01 + offset, -0.030 + mapUp, adjust(0.180, 0.258) },
        { 0.200 + offset, 0 + mapUp,      adjust(0.065, 0.20) },
        { 0 + offset,     0.015 + mapUp,  adjust(0.252, 0.338) }
    }

    SetMinimapComponentPosition('minimap', 'L', 'B', table.unpack(p[1]))
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', table.unpack(p[2]))
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', table.unpack(p[3]))

    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetBigmapActive(true, false)
    Wait(50)
    SetBigmapActive(false, false)
    Wait(1200)
end)
