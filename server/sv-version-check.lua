local resourceName = "jg-hud"
local versionCheckUrl = "https://raw.githubusercontent.com/jgscripts/versions/main/" .. resourceName .. ".txt"

-- Compare two version strings semver style, returns true if current < latest
local function IsUpdateAvailable(currentVersion, latestVersion)
    local function splitVersion(version)
        local parts = {}
        for part in string.gmatch(version, "[^.]+") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end

    local currentParts = splitVersion(currentVersion)
    local latestParts = splitVersion(latestVersion)
    local maxLen = math.max(#currentParts, #latestParts)

    for i = 1, maxLen do
        local currentPart = currentParts[i] or 0
        local latestPart = latestParts[i] or 0
        if currentPart < latestPart then
            return true
        elseif currentPart > latestPart then
            return false
        end
    end

    return false
end

-- HTTP response handler for update check
local function HandleUpdateResponse(statusCode, responseText, _)
    if statusCode ~= 200 then
        print("^1Unable to perform update check")
        return
    end

    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    if not currentVersion then return end

    if currentVersion == "dev" then
        print("^3Using dev version")
        return
    end

    local latestVersion = responseText:match("^[^\r\n]+")
    if not latestVersion then return end

    if IsUpdateAvailable(currentVersion:sub(2), latestVersion:sub(2)) then
        print(string.format("^3Update available for %s! (current: ^1%s^3, latest: ^2%s^3)", resourceName, currentVersion, latestVersion))
        print("^3Release notes: discord.gg/jgscripts")
    end
end

PerformHttpRequest(versionCheckUrl, HandleUpdateResponse, "GET")

-- Additional server artifact version check
local function CheckArtifactVersion()
    local artifactVer = GetConvar("version", "unknown")
    local buildNum = tonumber(artifactVer:match("v%d+%.%d+%.%d+%.(%d+)"))

    PerformHttpRequest("https://artifacts.jgscripts.com/check?artifact=" .. (buildNum or ""), function(statusCode, responseText)
        if statusCode ~= 200 or not responseText then
            print("^1Could not check artifact version^0")
            return
        end

        local data = json.decode(responseText)
        if data and data.status == "BROKEN" then
            print("^1WARNING: The current FXServer version you are using (artifacts version) has known issues. Please update to the latest stable artifacts: https://artifacts.jgscripts.com^0")
            print("^0Artifact version:^3" .. (buildNum or "unknown") .. "\n\n^0Known issues:^3" .. (data.reason or "unknown"))
        end
    end)
end

CreateThread(CheckArtifactVersion)
