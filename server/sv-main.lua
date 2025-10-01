-- Enable fly-through windscreen globally
SetConvarReplicated("game_enableFlyThroughWindscreen", "true")

-- Background thread to check and stop conflicting resource
CreateThread(function()
    -- Wait 10 seconds before starting check
    Wait(10000)

    local ok, err = pcall(function()
        local resourceState = GetResourceState("jg-vehicleindicators")
        if resourceState == "started" then
            StopResource("jg-vehicleindicators")
        end
    end)

    if not ok then
        print("Warning: Failed to check or stop jg-vehicleindicators resource:", err)
    end
end)
