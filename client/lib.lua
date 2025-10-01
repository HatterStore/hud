function hasResource(resourceName)
    return GetResourceState(resourceName):match('start') ~= nil
end
