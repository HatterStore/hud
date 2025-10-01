local postalData = nil

CreateThread(function()
    if not Config.ShowNearestPostal then
        return
    end

    local ok, err = pcall(function()
        local dataFile = LoadResourceFile(GetCurrentResourceName(), Config.NearestPostalsData)
        if not dataFile then
            print(string.format("Error: could not find postals data file: %s", Config.NearestPostalsData))
            return
        end

        local decoded = json.decode(dataFile)
        postalData = decoded

        for i, postal in ipairs(postalData) do
            postalData[i] = {
                vec2(postal.x, postal.y),
                code = postal.code,
            }
        end
    end)
    if not ok then
        print("Error loading nearest postal data:", err)
    end
end)

function GetNearestPostal()
    if not Config.ShowNearestPostal then
        return false
    end

    if not postalData then
        return false
    end

    local count = #postalData
    local playerCoords = GetEntityCoords(cache.ped).xy

    local nearestIndex = nil
    local nearestDistance = nil

    for i = 1, count do
        local postalCoords = postalData[i][1]
        local dist = #(playerCoords - postalCoords)

        if not nearestDistance or dist < nearestDistance then
            nearestIndex = i
            nearestDistance = dist
        end
    end

    local nearestPostal = postalData[nearestIndex]
    local code = nearestPostal.code

    local convertedDistance = math.round(
        Framework.Client.ConvertDistance(
            nearestDistance,
            UserSettingsData and UserSettingsData.distanceMeasurement
        )
    )

    return {
        code = code,
        dist = convertedDistance,
    }
end
