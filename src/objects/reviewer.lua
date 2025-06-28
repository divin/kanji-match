local json = require("libs.json")

local Reviewer = {}
Reviewer.__index = Reviewer

-- Constructor
function Reviewer:new()
    local instance = setmetatable({}, Reviewer)
    instance.states = {} -- SRS states for each kanji
    instance.srsFileName = "srsData.json"
    return instance
end

-- Privat method to load the data
function Reviewer:_loadData()
    local existingData = {}
    local srsFileContent = love.filesystem.read(self.srsFileName)

    if srsFileContent then
        local success, decoded = pcall(json.decode, srsFileContent)
        if success and type(decoded) == "table" then
            existingData = decoded
        end
    end

    return existingData
end

-- Method to load the SRS state from a file
function Reviewer:loadSRSState(kanjiData)
    assert(type(kanjiData) == "table", "kanjiData must be a table")

    -- Try to load existing SRS data from file
    self.states = {}
    local existingData = {}
    if love.filesystem.getInfo(self.srsFileName) then
        existingData = self:_loadData()
        assert(type(existingData) == "table", "Loaded SRS data must be a table")
    end

    -- Merge existing data with current kanji data
    for _, group in ipairs(kanjiData) do
        assert(type(group) == "table", "Each group in kanjiData must be a table")
        for _, kanji in ipairs(group) do
            assert(type(kanji) == "table", "Each kanji in group must be a table")
            assert(type(kanji.character) == "string", "Each kanji must have a character string")

            local kanjiChar = kanji.character
            if existingData[kanjiChar] then
                -- Validate existing data structure
                local existingState = existingData[kanjiChar]
                if type(existingState) == "table" and
                    type(existingState.n) == "number" and
                    type(existingState.efactor) == "number" and
                    type(existingState.interval) == "number" and
                    type(existingState.lastReviewed) == "number" then
                    self.states[kanjiChar] = existingState
                else
                    -- Invalid structure, initialize new state
                    self.states[kanjiChar] = nil
                end
            else
                -- New kanji, will be initialized on first review
                self.states[kanjiChar] = nil
            end
        end
    end
end

-- Method to save the SRS state to a file
function Reviewer:saveSRSState()
    -- Create a clean copy of SRS states for saving
    local dataToSave = {}
    local saveCount = 0

    for kanjiChar, state in pairs(self.states) do
        if state ~= nil then
            -- Validate state structure before saving
            assert(type(state.n) == "number", "Invalid SRS state: n must be a number for " .. kanjiChar)
            assert(type(state.efactor) == "number", "Invalid SRS state: efactor must be a number for " .. kanjiChar)
            assert(type(state.interval) == "number", "Invalid SRS state: interval must be a number for " .. kanjiChar)
            assert(type(state.lastReviewed) == "number",
                "Invalid SRS state: lastReviewed must be a number for " .. kanjiChar)

            -- Only save kanji that have been reviewed at least once
            dataToSave[kanjiChar] = {
                n = state.n,
                efactor = state.efactor,
                interval = state.interval,
                lastReviewed = state.lastReviewed,
                nextReview = state.nextReview, -- Add next review timestamp
                -- Add metadata for future compatibility
                version = "1.0",
                lastUpdated = os.time()
            }
            saveCount = saveCount + 1
        end
    end

    -- Save to file
    local success, encoded = pcall(json.encode, dataToSave)
    assert(success, "Failed to encode SRS data to JSON")

    local writeSuccess = love.filesystem.write(self.srsFileName, encoded)
    assert(writeSuccess, "Failed to write SRS data to file: " .. self.srsFileName)
end

-- Method to update SRS state for a kanji
function Reviewer:updateSRSState(kanjiCharacter, passed)
    assert(type(kanjiCharacter) == "string" and kanjiCharacter ~= "", "kanjiCharacter must be a non-empty string")
    assert(type(passed) == "boolean", "passed must be a boolean")

    local srsFunc = require("utils.spaceRepetition")
    local currentTime = os.time() / (24 * 60 * 60) -- Current time in days since epoch
    local previousState = self.states[kanjiCharacter]

    -- Calculate lateness (0 for new cards or immediate practice)
    local lateness = 0
    if previousState and previousState.lastReviewed then
        local expectedReviewTime = previousState.lastReviewed + previousState.interval
        lateness = (currentTime - expectedReviewTime) / previousState.interval
    end

    -- Create evaluation
    local evaluation = {
        passed = passed,
        lateness = lateness
    }

    -- Calculate new SRS state
    local newState = srsFunc(previousState, evaluation)
    assert(type(newState) == "table", "SRS function must return a table")
    assert(type(newState.n) == "number", "SRS state n must be a number")
    assert(type(newState.efactor) == "number", "SRS state efactor must be a number")
    assert(type(newState.interval) == "number", "SRS state interval must be a number")

    newState.lastReviewed = currentTime
    -- Calculate next review timestamp (in seconds since epoch)
    newState.nextReview = math.floor(os.time() + (newState.interval * 24 * 60 * 60))

    -- Store updated state
    self.states[kanjiCharacter] = newState
end

-- Method to get due groups based on SRS states
function Reviewer:getDueGroups(kanjiData)
    assert(type(kanjiData) == "table", "kanjiData must be a table")

    local currentTime = os.time() / (24 * 60 * 60) -- Current time in days since epoch
    local dueGroups = {}

    for _, group in ipairs(kanjiData) do
        assert(type(group) == "table", "Each group in kanjiData must be a table")
        local groupIsDue = false

        for _, kanji in ipairs(group) do
            assert(type(kanji) == "table", "Each kanji in group must be a table")
            assert(type(kanji.character) == "string", "Each kanji must have a character string")

            local kanjiChar = kanji.character
            local state = self.states[kanjiChar]

            -- New kanji (no state) are always due
            if not state then
                groupIsDue = true
                break
            end

            -- Check if review is due
            if state.lastReviewed then
                local nextReviewTime = state.lastReviewed + state.interval
                if currentTime >= nextReviewTime then
                    groupIsDue = true
                    break
                end
            else
                -- Kanji with state but no last reviewed time are due
                groupIsDue = true
                break
            end
        end

        if groupIsDue then
            table.insert(dueGroups, group)
        end
    end

    return dueGroups
end

-- Method to get all SRS states
function Reviewer:getStates()
    return self.states
end

-- Method to count keys in a table
function Reviewer:countKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

return Reviewer
