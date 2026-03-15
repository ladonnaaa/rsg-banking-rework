local resourceName = GetCurrentResourceName()
local githubRawBase = 'https://raw.githubusercontent.com/Rexshack-RedM/rsg-versioncheckers/main/'

local function printLog(type, message)
    local color = (type == 'success' and '^2') or (type == 'warning' and '^3') or '^1'
    print(('[%s]%s %s^7'):format(resourceName, color, message))
end

local function isVersionOutdated(current, latest)
    local function splitVersion(v)
        local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
        if major then return {tonumber(major), tonumber(minor) or 0, tonumber(patch) or 0} end
        return {0, 0, 0} 
    end

    local c = splitVersion(current)
    local l = splitVersion(latest)

    for i = 1, 3 do
        if l[i] > c[i] then return true
        elseif l[i] < c[i] then return false
        end
    end
    return false
end

CreateThread(function()
    local currentVersion = GetResourceMetadata(resourceName, 'version')
    if not currentVersion then return end
    local versionUrl = githubRawBase .. resourceName .. '/version.txt'

    PerformHttpRequest(versionUrl, function(statusCode, remoteVersion)
        if statusCode ~= 200 or not remoteVersion or remoteVersion == '' then return end
        remoteVersion = remoteVersion:gsub('%s+$', '')
        
        if currentVersion == remoteVersion then
            printLog('success', 'RSG Banking je aktuální!')
        elseif isVersionOutdated(currentVersion, remoteVersion) then
            printLog('error', ('Nová verze k dispozici! Prosím aktualizujte z %s na %s'):format(currentVersion, remoteVersion))
        end
    end, 'GET')
end)