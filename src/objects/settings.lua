local json = require("libs.json")

local Settings = {}
Settings.__index = Settings

function Settings:new(font)
    local instance = setmetatable({}, Settings)
    instance.userLevel = 1
    instance.font = font or love.graphics.getFont()
    instance.groupsPerLesson = 15
    instance.apiToken = ""
    instance.isValidToken = false
    instance.activeSubscription = false
    instance.maxGrantedLevel = 1
    instance.soundEffectVolume = 5 -- Default: 5 (range 0-10)
    instance.confettiAmount = 50   -- Default: 50 (range 0-100)
    return instance
end

function Settings:save()
    local settingsFile = "settings.json"
    love.filesystem.write(settingsFile, json.encode(self))
end

function Settings:load()
    local settingsFile = "settings.json"
    if love.filesystem.getInfo(settingsFile) then
        local settingsData = love.filesystem.read(settingsFile)
        local loadedSettings = json.decode(settingsData)
        for key, value in pairs(loadedSettings) do
            self[key] = value
        end
    else
        -- Save default settings if no settings file exists
        self:save()
    end
end

return Settings
