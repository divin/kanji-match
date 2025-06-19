local json = require("libs.json")
local https = require("https")
local BaseScene = require("scenes.baseScene")

-- Create a new scene object, inheriting from BaseScene
local HTTPSExampleScene = BaseScene:new()
HTTPSExampleScene.__index = HTTPSExampleScene

-- Called once when the scene is first loaded.
function HTTPSExampleScene:load()
    -- Hardcoded API token for testing (replace with your actual token)
    self.apiToken = "YOUR_API_TOKEN_HERE"

    self.userLevel = nil
    self.kanjiData = {}
    self.status = "Press ENTER to fetch WaniKani data"
    self.errorMessage = ""
    self.isLoading = false

    -- UI elements
    self.titleFont = love.graphics.newFont(24)
    self.statusFont = love.graphics.newFont(16)
    self.dataFont = love.graphics.newFont(14)

    -- Colors
    self.colors = {
        background = { 0.1, 0.1, 0.2, 1 },
        white = { 1, 1, 1, 1 },
        green = { 0.2, 0.8, 0.2, 1 },
        red = { 0.8, 0.2, 0.2, 1 },
        blue = { 0.3, 0.3, 0.8, 1 },
        gray = { 0.5, 0.5, 0.5, 1 }
    }
end

function HTTPSExampleScene:fetchUserData()
    if self.apiToken == "YOUR_API_TOKEN_HERE" then
        self.errorMessage = "Please set your API token in the code"
        return
    end

    self.status = "Fetching user data..."
    self.errorMessage = ""
    self.isLoading = true

    -- Fetch user information
    local code, body, headers = https.request("https://api.wanikani.com/v2/user", {
        headers = {
            ["Authorization"] = "Bearer " .. self.apiToken,
            ["Wanikani-Revision"] = "20170710"
        }
    })

    if code == 200 then
        -- Parse JSON response
        local success, userData = pcall(json.decode, body)
        if success and userData.data and userData.data.level then
            self.userLevel = userData.data.level
            self.status = "User data fetched! Level: " .. self.userLevel
            self:fetchKanjiData()
        else
            self.errorMessage = "Failed to parse user data"
            self.status = "Error parsing user data"
            self.isLoading = false
        end
    elseif code == 401 then
        self.errorMessage = "Invalid API token"
        self.status = "Authentication failed"
        self.isLoading = false
    else
        self.errorMessage = "HTTP Error: " .. code
        self.status = "Failed to fetch user data"
        self.isLoading = false
    end
end

function HTTPSExampleScene:fetchKanjiData()
    self.status = "Fetching kanji data..."

    -- Fetch kanji subjects with visually similar data
    local code, body, headers = https.request("https://api.wanikani.com/v2/subjects?types=kanji", {
        headers = {
            ["Authorization"] = "Bearer " .. self.apiToken,
            ["Wanikani-Revision"] = "20170710"
        }
    })

    if code == 200 then
        self:parseKanjiData(body)
        self.status = "Kanji data fetched! Found " .. #self.kanjiData .. " kanji with similar variants"
        self.isLoading = false
    else
        self.errorMessage = "Failed to fetch kanji data: " .. code
        self.status = "Error fetching kanji data"
        self.isLoading = false
    end
end

function HTTPSExampleScene:parseKanjiData(jsonBody)
    -- Parse JSON response using json library
    self.kanjiData = {}

    local success, response = pcall(json.decode, jsonBody)
    if not success or not response.data then
        self.errorMessage = "Failed to parse kanji JSON data"
        return
    end

    -- Process each kanji subject
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

function HTTPSExampleScene:saveKanjiData()
    if #self.kanjiData == 0 then
        self.errorMessage = "No kanji data to save"
        return
    end

    -- Create groups based on visually similar kanji
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

            -- Only add groups with multiple kanji (similar to original format)
            if #group > 1 then
                table.insert(kanjiGroups, group)
            end
        end
    end

    -- Convert to JSON
    local success, jsonOutput = pcall(json.encode, kanjiGroups)
    if not success then
        self.errorMessage = "Failed to encode kanji data to JSON"
        return
    end

    -- Save to file (Love2D file system)
    local fileSuccess = love.filesystem.write("wanikani_kanji_groups.json", jsonOutput)
    if fileSuccess then
        self.status = "Kanji groups saved to wanikani_kanji_groups.json! (" .. #kanjiGroups .. " groups)"
    else
        self.errorMessage = "Failed to save kanji data file"
    end
end

-- Called every frame to draw the scene.
function HTTPSExampleScene:draw()
    -- Background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    local y = 50

    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(self.colors.white)
    local title = "WaniKani API Integration Demo"
    local titleWidth = self.titleFont:getWidth(title)
    love.graphics.print(title, (love.graphics.getWidth() - titleWidth) / 2, y)
    y = y + 40

    -- Status
    love.graphics.setFont(self.statusFont)
    love.graphics.setColor(self.colors.blue)
    love.graphics.print(self.status, 50, y)
    y = y + 30

    -- Loading indicator
    if self.isLoading then
        love.graphics.setColor(self.colors.white)
        love.graphics.print("Loading...", 50, y)
        y = y + 25
    end

    -- Error message
    if self.errorMessage ~= "" then
        love.graphics.setColor(self.colors.red)
        love.graphics.print("Error: " .. self.errorMessage, 50, y)
        y = y + 30
    end

    -- Instructions
    love.graphics.setFont(self.statusFont)
    love.graphics.setColor(self.colors.white)
    love.graphics.print("Instructions:", 50, y)
    y = y + 20
    love.graphics.print("• Press ENTER to fetch WaniKani data", 50, y)
    y = y + 18
    love.graphics.print("• Press S to save kanji data to file", 50, y)
    y = y + 18
    love.graphics.print("• Press ESC to return to main game", 50, y)
    y = y + 30

    -- API Token info
    love.graphics.setColor(self.colors.gray)
    love.graphics.print("API Token: " .. (self.apiToken == "YOUR_API_TOKEN_HERE" and "Not set" or "Configured"), 50, y)
    y = y + 30

    -- User info
    if self.userLevel then
        love.graphics.setColor(self.colors.green)
        love.graphics.print("Authenticated! User Level: " .. self.userLevel, 50, y)
        y = y + 25

        if #self.kanjiData > 0 then
            love.graphics.print("Kanji with similar variants: " .. #self.kanjiData, 50, y)
            y = y + 25

            -- Show first few kanji as examples
            love.graphics.setFont(self.dataFont)
            love.graphics.setColor(self.colors.white)
            love.graphics.print("Sample kanji:", 50, y)
            y = y + 20

            for i = 1, math.min(8, #self.kanjiData) do
                local kanji = self.kanjiData[i]
                local text = string.format("%s (%s) - Level %d - %d similar",
                    kanji.character, kanji.meaning, kanji.level, #kanji.visually_similar_ids)
                love.graphics.print(text, 70, y)
                y = y + 18
            end

            if #self.kanjiData > 8 then
                love.graphics.setColor(self.colors.gray)
                love.graphics.print("... and " .. (#self.kanjiData - 8) .. " more", 70, y)
            end
        end
    end

    -- Reset color
    love.graphics.setColor(self.colors.white)
end

function HTTPSExampleScene:keypressed(key, scancode, isrepeat)
    if key == "return" then
        self:fetchUserData()
    elseif key == "s" then
        self:saveKanjiData()
    elseif key == "escape" then
        if SCENE_MANAGER then
            SCENE_MANAGER:switchTo("InitialScene")
        end
    end
end

function HTTPSExampleScene:keyreleased(key, scancode)
end

-- Return the scene object so it can be registered by the SceneManager
return HTTPSExampleScene
