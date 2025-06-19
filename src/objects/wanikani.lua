local https = require("https")
local json = require("libs.json")

local WaniKani = {}
WaniKani.__index = WaniKani

-- Constructor
function WaniKani:new(apiToken)
    local instance = setmetatable({}, WaniKani)
    instance.apiToken = apiToken or ""
    instance.baseUrl = "https://api.wanikani.com/v2"
    instance.revision = "20170710"
    instance.userLevel = nil
    instance.kanjiData = {}
    instance.isLoading = false
    instance.lastError = nil
    return instance
end

-- Private method to make HTTP requests to WaniKani API
function WaniKani:_makeRequest(endpoint, callback)
    if self.apiToken == "" then
        if callback then callback(false, "API token not set") end
        return
    end

    self.isLoading = true
    self.lastError = nil

    local url = self.baseUrl .. endpoint
    local code, body, headers = https.request(url, {
        headers = {
            ["Authorization"] = "Bearer " .. self.apiToken,
            ["Wanikani-Revision"] = self.revision
        }
    })

    self.isLoading = false

    if code == 200 then
        local success, data = pcall(json.decode, body)
        if success then
            if callback then callback(true, data) end
        else
            self.lastError = "Failed to parse JSON response"
            if callback then callback(false, self.lastError) end
        end
    elseif code == 401 then
        self.lastError = "Invalid API token"
        if callback then callback(false, self.lastError) end
    else
        self.lastError = "HTTP Error: " .. code
        if callback then callback(false, self.lastError) end
    end
end

-- Public method to get user level
function WaniKani:getUserLevel(callback)
    self:_makeRequest("/user", function(success, data)
        if success and data.data and data.data.level then
            self.userLevel = data.data.level
            if callback then callback(true, self.userLevel) end
        else
            if callback then callback(false, self.lastError or "Failed to get user level") end
        end
    end)
end

-- Public method to fetch kanji data with visually similar variants
function WaniKani:fetchKanjiData(callback)
    self:_makeRequest("/subjects?types=kanji", function(success, data)
        if success then
            self:_parseKanjiData(data)
            if callback then callback(true, self.kanjiData) end
        else
            if callback then callback(false, self.lastError or "Failed to fetch kanji data") end
        end
    end)
end

-- Private method to parse kanji data from API response
function WaniKani:_parseKanjiData(response)
    self.kanjiData = {}

    if not response.data then return end

    for _, subject in ipairs(response.data) do
        local data = subject.data
        if data and data.characters and data.visually_similar_subject_ids and #data.visually_similar_subject_ids > 0 then
            -- Get all meanings joined with commas
            local allMeanings = "Unknown"
            if data.meanings and #data.meanings > 0 then
                local meaningStrings = {}
                for _, meaning in ipairs(data.meanings) do
                    table.insert(meaningStrings, meaning.meaning)
                end
                allMeanings = table.concat(meaningStrings, ", ")
            end

            table.insert(self.kanjiData, {
                id = subject.id,
                character = data.characters,
                meaning = allMeanings,
                level = data.level,
                visually_similar_ids = data.visually_similar_subject_ids
            })
        end
    end
end

-- Public method to get formatted kanji groups (like kanji_groups.json)
function WaniKani:getKanjiGroups()
    local kanjiGroups = {}
    local processedIds = {}

    for _, kanji in ipairs(self.kanjiData) do
        if not processedIds[kanji.id] then
            -- Create a new group with this kanji and its visually similar ones
            local group = {}

            -- Add the main kanji
            table.insert(group, {
                character = kanji.character,
                meaning = kanji.meaning,
                level = kanji.level
            })
            processedIds[kanji.id] = true

            -- Find and add visually similar kanji from our data
            for _, similarId in ipairs(kanji.visually_similar_ids) do
                for _, otherKanji in ipairs(self.kanjiData) do
                    if otherKanji.id == similarId and not processedIds[similarId] then
                        table.insert(group, {
                            character = otherKanji.character,
                            meaning = otherKanji.meaning,
                            level = otherKanji.level
                        })
                        processedIds[similarId] = true
                        break
                    end
                end
            end

            -- Only add groups with multiple kanji
            if #group > 1 then
                table.insert(kanjiGroups, group)
            end
        end
    end

    return kanjiGroups
end

-- Public method to save kanji groups to JSON file
function WaniKani:saveKanjiGroups(filename, callback)
    local kanjiGroups = self:getKanjiGroups()

    if #kanjiGroups == 0 then
        if callback then callback(false, "No kanji groups to save") end
        return
    end

    local success, jsonOutput = pcall(json.encode, kanjiGroups)
    if not success then
        if callback then callback(false, "Failed to encode kanji data to JSON") end
        return
    end

    local fileSuccess = love.filesystem.write(filename or "wanikani_kanji_groups.json", jsonOutput)
    if fileSuccess then
        if callback then callback(true, "Saved " .. #kanjiGroups .. " kanji groups") end
    else
        if callback then callback(false, "Failed to save file") end
    end
end

-- Public method to check if currently loading
function WaniKani:isCurrentlyLoading()
    return self.isLoading
end

-- Public method to get last error
function WaniKani:getLastError()
    return self.lastError
end

-- Public method to get cached user level
function WaniKani:getCachedUserLevel()
    return self.userLevel
end

-- Public method to get cached kanji data
function WaniKani:getCachedKanjiData()
    return self.kanjiData
end

-- Public method to get kanji count
function WaniKani:getKanjiCount()
    return #self.kanjiData
end

-- Public method to get groups count
function WaniKani:getGroupsCount()
    return #self:getKanjiGroups()
end

return WaniKani
