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
    local code, body, _ = https.request(url, {
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

-- Private method to parse kanji data from API response and create groups
function WaniKani:_parseAndSaveKanjiData(response, filename, callback)
    local kanjiData = {}

    if not response.data then
        if callback then callback(false, "No data in response") end
        return
    end

    -- Parse kanji data - include ALL kanji, not just those with visually similar ones
    for _, subject in ipairs(response.data) do
        local data = subject.data
        if data and data.characters then
            -- Get all meanings joined with commas
            local allMeanings = "Unknown"
            if data.meanings and #data.meanings > 0 then
                local meaningStrings = {}
                for _, meaning in ipairs(data.meanings) do
                    table.insert(meaningStrings, meaning.meaning)
                end
                allMeanings = table.concat(meaningStrings, ", ")
            end

            -- Include visually similar IDs if they exist, otherwise empty table
            local visuallySimilarIds = {}
            if data.visually_similar_subject_ids then
                visuallySimilarIds = data.visually_similar_subject_ids
            end

            table.insert(kanjiData, {
                id = subject.id,
                character = data.characters,
                meaning = allMeanings,
                level = data.level,
                visually_similar_ids = visuallySimilarIds
            })
        end
    end

    -- Create kanji groups
    local kanjiGroups = {}
    local processedIds = {}

    for _, kanji in ipairs(kanjiData) do
        if not processedIds[kanji.id] and #kanji.visually_similar_ids > 0 then
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
                for _, otherKanji in ipairs(kanjiData) do
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

            -- Add groups with at least one kanji (changed from multiple)
            if #group >= 1 then
                table.insert(kanjiGroups, group)
            end
        end
    end

    -- If no groups were created from visually similar logic, create individual groups
    if #kanjiGroups == 0 then
        for _, kanji in ipairs(kanjiData) do
            table.insert(kanjiGroups, { {
                character = kanji.character,
                meaning = kanji.meaning,
                level = kanji.level
            } })
        end
    end

    -- Save to file
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

-- Public method to get user information
function WaniKani:getUserInfo(callback)
    self:_makeRequest("/user", function(success, data)
        if success and data.data then
            if callback then callback(true, data.data) end
        else
            if callback then callback(false, self.lastError or "Failed to get user info") end
        end
    end)
end

-- Public method to fetch kanji data up to a given max level, arrange it, and save it
function WaniKani:fetchKanjiData(maxLevel, filename, callback)
    assert(type(maxLevel) == "number", "Max level must be a number")

    local endpoint
    if maxLevel == 60 then
        -- If max level is 60, omit the level parameter to get all kanji
        endpoint = "/subjects?types=kanji"
    else
        -- If max level is below 60, filter by levels 1 to maxLevel
        local levels = {}
        for i = 1, maxLevel do
            table.insert(levels, tostring(i))
        end
        endpoint = "/subjects?types=kanji&levels=" .. table.concat(levels, ",")
    end

    self:_makeRequest(endpoint, function(success, data)
        if success then
            self:_parseAndSaveKanjiData(data, filename, callback)
        else
            if callback then callback(false, self.lastError or "Failed to fetch kanji data") end
        end
    end)
end

return WaniKani
