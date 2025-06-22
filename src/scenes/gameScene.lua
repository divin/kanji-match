local Card = require("objects.card")
local BaseScene = require("scenes.baseScene")
local shuffleTable = require("utils.shuffleTable")
local getKanjiDataForLevel = require("utils.kanjiData")
local srsFunc = require("utils.spaceRepetition")
local Confetti = require("objects.confetti")

-- Create a new scene object, inheriting from BaseScene
local GameScene = BaseScene:new()
GameScene.__index = GameScene -- For proper method lookup if methods are added after new()

-- Called once when the scene is first loaded.
function GameScene:enter(...)
    self.kanjiData = getKanjiDataForLevel(SETTINGS.userLevel)

    self.maxCols = 5
    self.maxRows = 4
    self.spacing = 16
    self.cardWidth = 128
    self.cardHeight = 128

    self.cardSets = {}
    self.currentSet = {}
    self.currentIndex = 1
    self.currentSetIndex = 1
    self.availableCards = nil
    self.completedCards = nil
    self.selectedCards = {}

    -- Streak tracking for pitch modification
    self.streak = 0
    self.streakConfig = {
        basePitch = 1.0,       -- Starting pitch for correct sound
        pitchIncrement = 0.15, -- How much pitch increases per streak
        maxPitch = 2.5,        -- Maximum pitch cap
        maxStreakDisplay = 10, -- Show streak counter up to this number
        resetOnMiss = true     -- Whether to reset streak on incorrect match
    }

    -- SRS tracking
    self.srsStates = self:loadSRSStates()
    self.dueGroups = self:getDueGroups()
    self.failedKanji = {} -- Track failed attempts to only count once per set

    -- Session tracking for overview
    self.sessionStats = {
        totalGroups = #self.dueGroups,
        completedGroups = 0,
        totalKanji = 0,
        correctMatches = 0,
        incorrectMatches = 0,
        maxStreak = 0,
        sessionStartTime = love.timer.getTime()
    }

    -- Save SRS states periodically
    self.lastSaveTime = love.timer.getTime()
    self.saveInterval = 30 -- Save every 30 seconds

    self.kanjiFont = love.graphics.newFont(SETTINGS.font, 40)
    self.meaningFont = love.graphics.newFont(SETTINGS.font, 14)
    self.streakFont = love.graphics.newFont(SETTINGS.font, 24)

    -- Initialize confetti
    self.confetti = {}
    self.colors = {
        { 1,   0.2, 0.2 }, -- Red
        { 0.2, 1,   0.2 }, -- Green
        { 0.2, 0.2, 1 },   -- Blue
        { 1,   1,   0.2 }, -- Yellow
        { 1,   0.2, 1 },   -- Magenta
        { 0.2, 1,   1 },   -- Cyan
        { 1,   0.6, 0.2 }, -- Orange
        { 0.6, 0.2, 1 },   -- Purple
    }
    self.shapes = { "rectangle", "circle", "triangle" }

    self:loadNextGroup()
end

-- Called when the scene is no longer the active scene
function GameScene:leave()
    -- Save SRS states before leaving the scene
    self:saveSRSStates()
end

-- Load the next group of kanji cards
function GameScene:loadNextGroup()
    -- Check if we have due groups to review
    if #self.dueGroups == 0 then
        print("No groups due for review!")
        return
    end

    -- Check if we have more groups
    if self.currentIndex > #self.dueGroups then
        print("All due groups completed!")
        return
    end

    -- Reset the lists
    self.cardSets = {}
    self.currentSetIndex = 1

    -- Get the current due group
    local dueGroupData = self.dueGroups[self.currentIndex]
    local kanjiGroup = dueGroupData.group
    print("Loading group " .. dueGroupData.groupIndex .. " for review: " .. #kanjiGroup .. " kanji (earliest due: " ..
        (dueGroupData.hasNewKanji and "new kanji" or string.format("%.2f days ago", (os.time() / (24 * 60 * 60)) - dueGroupData.earliestDueDate)) ..
        ")")

    -- Update session stats
    self.sessionStats.completedGroups = self.currentIndex - 1
    self.sessionStats.totalKanji = self.sessionStats.totalKanji + #kanjiGroup

    -- Define the dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local totalWidth = self.maxCols * self.cardWidth + (self.maxCols - 1) * self.spacing
    local totalHeight = self.maxRows * self.cardHeight + (self.maxRows - 1) * self.spacing

    -- Calculate cards per set (must be even for pairs)
    local maxCardsPerSet = self.maxRows * self.maxCols
    if maxCardsPerSet % 2 ~= 0 then
        maxCardsPerSet = maxCardsPerSet - 1 -- Make it even
    end

    -- Total cards needed (each kanji has character + meaning = 2 cards)
    local totalCards = #kanjiGroup * 2

    -- Calculate number of sets needed
    local numberOfSets = math.ceil(totalCards / maxCardsPerSet)
    local cardsPerSet = math.ceil(totalCards / numberOfSets)

    -- Make cardsPerSet even
    if cardsPerSet % 2 ~= 0 then
        cardsPerSet = cardsPerSet + 1
    end

    print("Creating " .. numberOfSets .. " sets with " .. cardsPerSet .. " cards each")

    -- Create all card data first
    local allCardData = {}
    for _, kanji in ipairs(kanjiGroup) do
        local id = kanji.character
        table.insert(allCardData, { text = kanji.character, pairId = id, type = "character" })
        table.insert(allCardData, { text = kanji.meaning, pairId = id, type = "meaning" })
    end

    -- Distribute cards across sets
    for setIndex = 1, numberOfSets do
        local cards = {}
        local setCardData = {}

        -- Get cards for this set
        local startIdx = (setIndex - 1) * cardsPerSet + 1
        local endIdx = math.min(startIdx + cardsPerSet - 1, #allCardData)

        for i = startIdx, endIdx do
            table.insert(setCardData, allCardData[i])
        end

        -- Shuffle the card data for this set
        setCardData = shuffleTable(setCardData)

        -- Create card objects positioned on screen
        local topMargin = 32 -- Space for streak counter and padding
        local startX = (screenWidth - totalWidth) / 2
        local startY = ((screenHeight - totalHeight) / 2) + topMargin

        for i = 1, #setCardData do
            local row = math.ceil(i / self.maxCols)
            local col = ((i - 1) % self.maxCols) + 1

            local x = startX + (col - 1) * (self.cardWidth + self.spacing)
            local y = startY + (row - 1) * (self.cardHeight + self.spacing)

            local cardData = setCardData[i]
            local font = cardData.type == "character" and self.kanjiFont or self.meaningFont

            local card = Card:new(
                x,                                    -- x position
                y,                                    -- y position
                cardData.text,                        -- text (character or meaning)
                self.cardWidth,                       -- width
                self.cardHeight,                      -- height
                font,                                 -- font
                function(c) self:onCardClicked(c) end -- onClick callback
            )
            card.pairId = cardData.pairId
            card.type = cardData.type
            table.insert(cards, card)
        end

        -- Add the set of cards to the cardSets
        table.insert(self.cardSets, cards)
    end

    -- Load the first set
    self:loadNextSet()
end

-- Load SRS states from file or initialize new ones
function GameScene:loadSRSStates()
    local json = require("libs.json")
    local states = {}
    local srsFileName = "srsData.json"

    -- Try to load existing SRS data from file
    local existingData = {}
    if love.filesystem.getInfo(srsFileName) then
        local srsFileContent = love.filesystem.read(srsFileName)
        if srsFileContent then
            local success, decoded = pcall(json.decode, srsFileContent)
            if success and type(decoded) == "table" then
                existingData = decoded
                print("Loaded SRS data for " .. self:countKeys(existingData) .. " kanji")
            else
                print("Warning: Failed to decode SRS data file, starting fresh")
            end
        end
    end

    -- Merge existing data with current kanji data
    for _, group in ipairs(self.kanjiData) do
        for _, kanji in ipairs(group) do
            local kanjiChar = kanji.character
            if existingData[kanjiChar] then
                -- Validate existing data structure
                local existingState = existingData[kanjiChar]
                if type(existingState) == "table" and
                    type(existingState.n) == "number" and
                    type(existingState.efactor) == "number" and
                    type(existingState.interval) == "number" and
                    type(existingState.lastReviewed) == "number" then
                    states[kanjiChar] = existingState
                else
                    print("Warning: Invalid SRS data for " .. kanjiChar .. ", resetting")
                    states[kanjiChar] = nil
                end
            else
                -- New kanji, will be initialized on first review
                states[kanjiChar] = nil
            end
        end
    end

    -- Clean up old data that's no longer available
    local removedCount = 0
    for kanjiChar, _ in pairs(existingData) do
        if not states[kanjiChar] then
            removedCount = removedCount + 1
        end
    end

    if removedCount > 0 then
        print("Removed SRS data for " .. removedCount .. " kanji no longer available")
    end

    return states
end

-- Get groups that are due for review based on worst performing kanji in each group
function GameScene:getDueGroups()
    local currentTime = os.time() / (24 * 60 * 60) -- Current time in days since epoch
    local dueGroups = {}

    for groupIndex, group in ipairs(self.kanjiData) do
        local earliestDueDate = math.huge
        local hasNewKanji = false

        -- Find the earliest due date (worst performing) kanji in this group
        for _, kanji in ipairs(group) do
            local state = self.srsStates[kanji.character]
            if state == nil then
                -- New kanji, group is immediately due
                hasNewKanji = true
                earliestDueDate = currentTime
                break
            else
                local dueDate = state.lastReviewed + state.interval
                if dueDate < earliestDueDate then
                    earliestDueDate = dueDate
                end
            end
        end

        -- If the worst performing kanji in the group is due, include the entire group
        if hasNewKanji or currentTime >= earliestDueDate then
            table.insert(dueGroups, {
                groupIndex = groupIndex,
                group = group,
                earliestDueDate = earliestDueDate,
                hasNewKanji = hasNewKanji
            })
        end
    end

    -- Sort groups by earliest due date (most overdue first)
    table.sort(dueGroups, function(a, b)
        if a.hasNewKanji and not b.hasNewKanji then
            return true
        elseif not a.hasNewKanji and b.hasNewKanji then
            return false
        else
            return a.earliestDueDate < b.earliestDueDate
        end
    end)

    -- Limit to groupsPerLesson setting
    local limitedGroups = {}
    local maxGroups = SETTINGS.groupsPerLesson or 5
    -- Ensure at least 1 group is shown if any are available
    if maxGroups < 1 and #dueGroups > 0 then
        maxGroups = 1
    end
    for i = 1, math.min(#dueGroups, maxGroups) do
        table.insert(limitedGroups, dueGroups[i])
    end

    print("Found " ..
        #dueGroups .. " groups due for review, showing " .. #limitedGroups .. " (limited by groupsPerLesson)")
    return limitedGroups
end

-- Save SRS states to file
function GameScene:saveSRSStates()
    local json = require("libs.json")
    local srsFileName = "srsData.json"

    -- Create a clean copy of SRS states for saving
    local dataToSave = {}
    local saveCount = 0

    for kanjiChar, state in pairs(self.srsStates) do
        if state ~= nil then
            -- Only save kanji that have been reviewed at least once
            dataToSave[kanjiChar] = {
                n = state.n,
                efactor = state.efactor,
                interval = state.interval,
                lastReviewed = state.lastReviewed,
                -- Add metadata for future compatibility
                version = "1.0",
                lastUpdated = os.time()
            }
            saveCount = saveCount + 1
        end
    end

    -- Save to file
    local success, encoded = pcall(json.encode, dataToSave)
    if success then
        local writeSuccess = love.filesystem.write(srsFileName, encoded)
        if writeSuccess then
            print("Successfully saved SRS data for " .. saveCount .. " kanji")
        else
            print("Error: Failed to write SRS data to file")
        end
    else
        print("Error: Failed to encode SRS data for saving")
    end
end

-- Helper function to count keys in a table
function GameScene:countKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Auto-save SRS states periodically during gameplay
function GameScene:autoSaveSRSStates()
    local currentTime = love.timer.getTime()
    if currentTime - self.lastSaveTime >= self.saveInterval then
        self:saveSRSStates()
        self.lastSaveTime = currentTime
    end
end

-- Complete the session and switch to game overview
function GameScene:completeSession()
    -- Update final session stats
    self.sessionStats.completedGroups = self.sessionStats.totalGroups
    self.sessionStats.sessionTime = love.timer.getTime() - self.sessionStats.sessionStartTime

    -- Final save of SRS states before completing session
    self:saveSRSStates()

    print("Session completed! Switching to game overview...")

    -- Switch to game overview scene with stats
    SCENE_MANAGER:switchTo(SCENES.gameOverviewScene, self.sessionStats)
end

-- Update SRS state for a kanji
function GameScene:updateSRSState(kanjiCharacter, passed)
    local currentTime = os.time() / (24 * 60 * 60) -- Current time in days since epoch
    local previousState = self.srsStates[kanjiCharacter]

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
    newState.lastReviewed = currentTime

    -- Store updated state
    self.srsStates[kanjiCharacter] = newState

    print("Updated SRS for " ..
        kanjiCharacter .. ": n=" .. newState.n .. ", interval=" .. string.format("%.2f", newState.interval) .. " days")

    -- Trigger auto-save check
    self:autoSaveSRSStates()
end

function GameScene:loadNextSet()
    -- Check if we have more sets in current group
    if self.currentSetIndex > #self.cardSets then
        print("All sets in group completed!")
        return false
    end

    -- Load the current set
    self.currentSet = self.cardSets[self.currentSetIndex]

    -- Reset failed kanji tracking for new set
    self.failedKanji = {}

    print("Loading set " .. self.currentSetIndex .. " of " .. #self.cardSets .. " (Group " .. self.currentIndex .. ")")
    print("Set has " .. #self.currentSet .. " cards")

    return true
end

function GameScene:shootConfetti(direction)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Determine cannon position
    local margin = 0
    local x = margin
    local y = margin
    local minAngle = 15
    local maxAngle = 60
    if direction == "upper-left" then
        x = margin
        y = margin
        minAngle = 315
        maxAngle = 360
    elseif direction == "upper-right" then
        x = screenWidth - margin
        y = margin
        minAngle = 315
        maxAngle = 360
    elseif direction == "lower-right" then
        x = screenWidth - margin
        y = screenHeight - margin
        minAngle = 15
        maxAngle = 60
    elseif direction == "lower-left" then
        x = margin
        y = screenHeight - margin
        minAngle = 15
        maxAngle = 60
    end


    -- Create multiple confetti particles
    local minConfettis = 25
    local maxConfettis = 75
    for i = 1, math.random(minConfettis, maxConfettis) do
        local color = self.colors[math.random(#self.colors)]
        local shape = self.shapes[math.random(#self.shapes)]

        -- Calculate launch velocity
        local angle = math.random(minAngle, maxAngle)
        angle = math.rad(angle)

        local minSpeed = 200
        local maxSpeed = 500
        local speed = math.random(minSpeed, maxSpeed)
        local vx = math.cos(angle) * speed
        local vy = -math.sin(angle) * speed

        -- Adjust direction based on cannon side
        if direction == "upper-right" or direction == "lower-right" then
            vx = -vx
        end

        -- Add some randomness
        vx = vx + (math.random() - 0.5) * 100
        vy = vy + (math.random() - 0.5) * 100

        local confettiPiece = Confetti:new(x, y, vx, vy, color, shape)
        table.insert(self.confetti, confettiPiece)
    end
end

function GameScene:addSelectedCard(card)
    love.audio.stop(SOUND_SOURCES.click)
    love.audio.play(SOUND_SOURCES.click)
    table.insert(self.selectedCards, card)
end

function GameScene:removeSelectedCard(card)
    love.audio.stop(SOUND_SOURCES.unclick)
    love.audio.play(SOUND_SOURCES.unclick)
    for i = #self.selectedCards, 1, -1 do
        if self.selectedCards[i] == card then
            table.remove(self.selectedCards, i)
            break
        end
    end
end

function GameScene:onCardClicked(card)
    print("Card clicked:", card.text, "Type:", card.type)
    -- Check if card is already selected - if so, deselect it
    if card.isSelected then
        card.isSelected = false
        self:removeSelectedCard(card)
        return
    end

    -- Don't allow more than 2 selections
    if #self.selectedCards >= 2 then
        return
    end

    -- Select the card
    card.isSelected = true
    self:addSelectedCard(card)

    if #self.selectedCards == 2 then
        local a, b = unpack(self.selectedCards)

        if a.pairId == b.pairId then
            print("Matched!", a.text, b.text)

            -- Increase streak and calculate new pitch
            self.streak = self.streak + 1
            local newPitch = math.min(
                self.streakConfig.basePitch + (self.streak * self.streakConfig.pitchIncrement),
                self.streakConfig.maxPitch
            )

            print("Streak: " .. self.streak .. ", Pitch: " .. string.format("%.2f", newPitch))

            -- Apply pitch and play correct sound
            love.audio.stop(SOUND_SOURCES.click)
            love.audio.stop(SOUND_SOURCES.correct)
            SOUND_SOURCES.correct:setPitch(newPitch)
            love.audio.play(SOUND_SOURCES.correct)

            -- Create confetti explosion
            self:shootConfetti("upper-left")  -- Left cannon
            self:shootConfetti("upper-right") -- Right cannon
            self:shootConfetti("lower-left")  -- Left cannon
            self:shootConfetti("lower-right") -- Right cannon

            -- Update SRS state for successful match
            self:updateSRSState(a.pairId, true)

            -- Update session stats
            self.sessionStats.correctMatches = self.sessionStats.correctMatches + 1
            if self.streak > self.sessionStats.maxStreak then
                self.sessionStats.maxStreak = self.streak
            end

            -- Remove matched cards from current set
            for i = #self.currentSet, 1, -1 do
                local c = self.currentSet[i]
                if c.pairId == a.pairId then
                    print("Removing card:", c.text)
                    table.remove(self.currentSet, i)
                end
            end

            -- Check if all cards are matched (set is empty)
            if #self.currentSet == 0 then
                print("All cards matched! Loading next set/group...")
                -- Save SRS states after completing a set
                self:saveSRSStates()

                -- Try to load next set first
                self.currentSetIndex = self.currentSetIndex + 1
                if not self:loadNextSet() then
                    -- No more sets in current group, try next group
                    self.currentIndex = self.currentIndex + 1
                    if self.currentIndex > #self.dueGroups then
                        self:completeSession()
                    end
                    self:loadNextGroup()
                end
            end
        else
            print("No match:", a.text, b.text)

            -- Update session stats for incorrect match
            self.sessionStats.incorrectMatches = self.sessionStats.incorrectMatches + 1

            -- Reset streak on incorrect match (if configured to do so)
            if self.streakConfig.resetOnMiss then
                self.streak = 0
                print("Streak reset to 0")

                -- Reset pitch to base value
                SOUND_SOURCES.correct:setPitch(self.streakConfig.basePitch)
            end

            love.audio.stop(SOUND_SOURCES.incorrect)
            love.audio.play(SOUND_SOURCES.incorrect)

            -- Update SRS state for failed match only if not already failed in this set
            if not self.failedKanji[a.pairId] then
                self:updateSRSState(a.pairId, false)
                self.failedKanji[a.pairId] = true
                print("First failure for " .. a.pairId .. " - SRS updated")
            else
                print("Already failed " .. a.pairId .. " in this set - SRS not updated")
            end

            a.isSelected, b.isSelected = false, false
        end

        -- clear selections so you can pick the next pair
        self.selectedCards = {}
    end
end

function GameScene:keyreleased(key, scancode)
end

-- Called every frame to draw the scene.
function GameScene:draw()
    -- Draw all cards in current set
    if self.currentSet then
        for _, card in ipairs(self.currentSet) do
            card:draw()
        end
    end

    -- Draw streak counter
    if self.streak > 0 and self.streak <= self.streakConfig.maxStreakDisplay then
        love.graphics.setFont(self.streakFont)
        -- Color based on streak level (yellow -> orange -> red)
        local intensity = math.min(self.streak / 5, 1)
        love.graphics.setColor(1, 1 - intensity * 0.5, 1 - intensity, 1)

        local streakText = "Streak: " .. self.streak
        local textWidth = self.streakFont:getWidth(streakText)
        love.graphics.print(streakText, love.graphics.getWidth() - textWidth - 20, 20)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    elseif self.streak > self.streakConfig.maxStreakDisplay then
        love.graphics.setFont(self.streakFont)
        love.graphics.setColor(1, 0.2, 0.2, 1) -- Bright red for high streaks

        local streakText = "Streak: " .. self.streak .. "!"
        local textWidth = self.streakFont:getWidth(streakText)
        love.graphics.print(streakText, love.graphics.getWidth() - textWidth - 20, 20)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- Draw all confetti
    for _, piece in ipairs(self.confetti) do
        piece:draw()
    end
end

function GameScene:update(dt)
    -- Update all confetti particles
    for i = #self.confetti, 1, -1 do
        local piece = self.confetti[i]
        if not piece:update(dt) then
            table.remove(self.confetti, i)
        end
    end

    -- Auto-save SRS states periodically
    self:autoSaveSRSStates()
end

function GameScene:mousemoved(x, y, dx, dy, istouch)
    -- Check if the mouse is hovering over any card
    if self.currentSet then
        for _, card in ipairs(self.currentSet) do
            if card:isPointInside(x, y) then
                card.isHovered = true
            else
                card.isHovered = false
            end
        end
    end
end

function GameScene:mousepressed(x, y, button, istouch, presses)
    -- Check if any card was clicked
    if self.currentSet then
        for _, card in ipairs(self.currentSet) do
            if card:isPointInside(x, y) and button == 1 then -- Left mouse button
                card:onClick()
                return
            end
        end
    end
end

return GameScene
