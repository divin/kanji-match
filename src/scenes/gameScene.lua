local srsUtils = require("utils.srsUtils")
local BaseScene = require("scenes.baseScene")
local getKanjiDataForLevel = require("utils.kanjiData")
local ConfettiCannon = require("objects.confettiCannon")
local Reviewer = require("objects.reviewer")
local SessionTracker = require("objects.sessionTracker")
local CardLayoutManager = require("objects.cardLayoutManager")
local MatchingGameLogic = require("objects.matchingGameLogic")

-- Cancel/exit button config
local EXIT_BTN_SIZE = 36
local EXIT_BTN_PADDING = 12

-- Create a new scene object, inheriting from BaseScene
local GameScene = BaseScene:new()
GameScene.__index = GameScene -- For proper method lookup if methods are added after new()

-- Called once when the scene is first loaded.
function GameScene:enter(dueGroups, ...)
    -- Validate required globals
    assert(SETTINGS, "SETTINGS global is required")
    assert(SETTINGS.userLevel, "SETTINGS.userLevel is required")
    assert(SETTINGS.font, "SETTINGS.font is required")
    assert(SOUND_SOURCES, "SOUND_SOURCES global is required")
    assert(SCENE_MANAGER, "SCENE_MANAGER global is required")
    assert(SCENES, "SCENES global is required")

    self.reviewer = Reviewer:new()
    assert(self.reviewer, "Failed to create Reviewer object")

    -- Exit button hover state
    self.exitBtnHovered = false

    -- For displaying next review info
    self.nextReviewMessage = nil
    self.nextReviewMessageTimer = 0

    self.kanjiData = getKanjiDataForLevel(SETTINGS.userLevel)
    assert(self.kanjiData, "Failed to load kanji data for level " .. tostring(SETTINGS.userLevel))
    assert(type(self.kanjiData) == "table", "Kanji data must be a table")
    assert(#self.kanjiData > 0, "Kanji data cannot be empty")

    -- Card layout configuration
    self.cardLayoutManager = CardLayoutManager:new(5, 4, 128, 128, 16, 32)
    assert(self.cardLayoutManager, "Failed to create CardLayoutManager object")

    self.cardSets = {}
    self.currentSet = {}
    self.currentIndex = 1
    self.currentSetIndex = 1
    self.availableCards = nil
    self.completedCards = nil

    -- SRS tracking
    self.reviewer:loadSRSState(self.kanjiData)
    self.srsStates = self.reviewer:getStates()
    assert(self.srsStates, "Failed to get SRS states from reviewer")

    if dueGroups ~= nil then
        self.dueGroups = dueGroups
    else
        self.dueGroups = self:getDueGroups()
    end
    assert(self.dueGroups, "Failed to get due groups")
    assert(type(self.dueGroups) == "table", "Due groups must be a table")

    -- Matching game logic
    self.matchingLogic = MatchingGameLogic:new(2)
    assert(self.matchingLogic, "Failed to create MatchingGameLogic object")
    self:_setupMatchingCallbacks()

    -- Session tracking
    self.sessionTracker = SessionTracker:new(#self.dueGroups)
    assert(self.sessionTracker, "Failed to create SessionTracker object")

    -- Save SRS states periodically
    self.lastSaveTime = love.timer.getTime()
    self.saveInterval = 30 -- Save every 30 seconds

    self.kanjiFont = love.graphics.newFont(SETTINGS.font, 48)
    assert(self.kanjiFont, "Failed to create kanji font")

    self.meaningFont = love.graphics.newFont(SETTINGS.font, 14)
    assert(self.meaningFont, "Failed to create meaning font")

    self.streakFont = love.graphics.newFont(SETTINGS.font, 24)
    assert(self.streakFont, "Failed to create streak font")

    -- Initialize confetti cannon with confetti amount from settings
    local confettiAmount = SETTINGS.confettiAmount
    self.confettiCannon = ConfettiCannon:new(0, confettiAmount, nil, nil, nil, nil)
    assert(self.confettiCannon, "Failed to create ConfettiCannon object")

    self:loadNextGroup()
end

-- Setup callbacks for matching game logic
function GameScene:_setupMatchingCallbacks()
    self.matchingLogic:setCallbacks({
        onCardSelected = function(card)
            assert(SOUND_SOURCES.click, "SOUND_SOURCES.click is required")
            love.audio.stop(SOUND_SOURCES.click)
            SOUND_SOURCES.click:setVolume(SETTINGS.soundEffectVolume / 10)
            love.audio.play(SOUND_SOURCES.click)
        end,

        onCardDeselected = function(card)
            assert(SOUND_SOURCES.unclick, "SOUND_SOURCES.unclick is required")
            love.audio.stop(SOUND_SOURCES.unclick)
            SOUND_SOURCES.unclick:setVolume(SETTINGS.soundEffectVolume / 10)
            love.audio.play(SOUND_SOURCES.unclick)
        end,

        onMatch = function(cardA, cardB)
            -- Record correct match and get new pitch
            self.sessionTracker:recordCorrectMatch(cardA.pairId)
            local newPitch = self.sessionTracker:getAudioPitch()

            -- Apply pitch and play correct sound
            assert(SOUND_SOURCES.correct, "SOUND_SOURCES.correct is required")
            love.audio.stop(SOUND_SOURCES.click)
            love.audio.stop(SOUND_SOURCES.correct)
            SOUND_SOURCES.correct:setPitch(newPitch)
            SOUND_SOURCES.correct:setVolume(SETTINGS.soundEffectVolume / 10)
            love.audio.play(SOUND_SOURCES.correct)

            -- Create confetti explosion
            self.confettiCannon:celebrate()

            -- Update SRS state for successful match
            self:updateSRSState(cardA.pairId, true)
        end,

        onMismatch = function(cardA, cardB, isFirstFailure)
            -- Record incorrect match and handle streak reset
            self.sessionTracker:recordIncorrectMatch(cardA.pairId)

            -- Reset pitch to base value
            SOUND_SOURCES.correct:setPitch(self.sessionTracker:getBasePitch())

            assert(SOUND_SOURCES.incorrect, "SOUND_SOURCES.incorrect is required")
            love.audio.stop(SOUND_SOURCES.incorrect)
            SOUND_SOURCES.incorrect:setVolume(SETTINGS.soundEffectVolume / 10)
            love.audio.play(SOUND_SOURCES.incorrect)

            -- Update SRS state for failed match only if first failure in this set
            if isFirstFailure then
                self:updateSRSState(cardA.pairId, false)
            end
        end,

        onSetComplete = function()
            -- Save SRS states after completing a set
            self.reviewer:saveSRSState()

            -- Show next review time for this group
            self:showNextReviewTimeForCurrentGroup()

            -- Try to load next set first
            self.currentSetIndex = self.currentSetIndex + 1
            if not self:loadNextSet() then
                -- No more sets in current group, mark group as completed
                self.sessionTracker:completeGroup()
                -- Try next group
                self.currentIndex = self.currentIndex + 1
                if self.currentIndex > #self.dueGroups then
                    self:completeSession()
                end
                self:loadNextGroup()
            end
        end
    })
end

-- Called when the scene is no longer the active scene
function GameScene:leave()
    -- Save SRS states before leaving the scene
    self.reviewer:saveSRSState()
end

-- Load the next group of kanji cards
function GameScene:loadNextGroup()
    -- Check if we have due groups to review
    if #self.dueGroups == 0 then
        return
    end

    -- Check if we have more groups
    if self.currentIndex > #self.dueGroups then
        return
    end

    -- Reset the lists
    self.cardSets = {}
    self.currentSetIndex = 1

    -- Get the current due group
    assert(self.currentIndex <= #self.dueGroups,
        "Current index " .. self.currentIndex .. " exceeds due groups count " .. #self.dueGroups)
    local dueGroupData = self.dueGroups[self.currentIndex]
    assert(dueGroupData, "Due group data is nil for index " .. self.currentIndex)
    assert(dueGroupData.group, "Due group data missing group field")

    local kanjiGroup = dueGroupData.group

    -- Update session stats (do not increment completedGroups here)
    self.sessionTracker:addKanji(#kanjiGroup)

    -- Create card sets using layout manager
    self.cardSets = self.cardLayoutManager:createCardSets(
        kanjiGroup,
        self.kanjiFont,
        self.meaningFont,
        function(c) self:onCardClicked(c) end
    )

    -- Load the first set
    self:loadNextSet()

    -- Reset failed items tracking for new group
    self.matchingLogic:resetFailedItems()
end

-- Get groups that are due for review based on worst performing kanji in each group
function GameScene:getDueGroups()
    -- Use the shared SRS utility for due group calculation
    return srsUtils.getDueGroups(self.kanjiData, self.srsStates, SETTINGS)
end

-- Auto-save SRS states periodically during gameplay
function GameScene:autoSaveSRSStates()
    local currentTime = love.timer.getTime()
    if currentTime - self.lastSaveTime >= self.saveInterval then
        self.reviewer:saveSRSState()
        self.lastSaveTime = currentTime
    end
end

-- Complete the session and switch to game overview
function GameScene:completeSession()
    -- Finalize session stats
    self.sessionTracker:finalizeSession()

    -- Final save of SRS states before completing session
    self.reviewer:saveSRSState()

    -- Switch to game overview scene with stats
    SCENE_MANAGER:switchTo(SCENES.gameOverviewScene, self.sessionTracker:getStats())
end

-- Update SRS state for a kanji
function GameScene:updateSRSState(kanjiCharacter, passed)
    -- Delegate to reviewer
    self.reviewer:updateSRSState(kanjiCharacter, passed)

    -- Update local reference to states
    self.srsStates = self.reviewer:getStates()

    -- Trigger auto-save check
    self:autoSaveSRSStates()
end

function GameScene:loadNextSet()
    -- Validate card sets exist
    assert(self.cardSets, "Card sets not initialized")
    assert(type(self.cardSets) == "table", "Card sets must be a table")

    -- Check if we have more sets in current group
    if self.currentSetIndex > #self.cardSets then
        return false
    end

    -- Load the current set
    assert(self.currentSetIndex <= #self.cardSets,
        "Current set index " .. self.currentSetIndex .. " exceeds card sets count " .. #self.cardSets)
    self.currentSet = self.cardSets[self.currentSetIndex]
    assert(self.currentSet, "Current set is nil for index " .. self.currentSetIndex)

    -- Reset failed items tracking for new set
    self.matchingLogic:resetFailedItems()

    return true
end

function GameScene:shootConfetti(direction)
    self.confettiCannon:shoot(direction)
end

function GameScene:onCardClicked(card)
    assert(card, "Card is nil in onCardClicked")
    assert(card.text, "Card text is nil")
    assert(card.type, "Card type is nil")
    assert(self.currentSet, "Current set is nil when handling card click")

    self.matchingLogic:handleCardClick(card, self.currentSet)
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
    local streakText = self.sessionTracker:getStreakText()
    if streakText ~= "" then
        love.graphics.setFont(self.streakFont)
        local color = self.sessionTracker:getStreakColor()
        love.graphics.setColor(color)

        local textWidth = self.streakFont:getWidth(streakText)
        love.graphics.print(streakText, love.graphics.getWidth() - textWidth - 20, 20)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- Draw exit/cancel button (top left)
    local btnX = EXIT_BTN_PADDING
    local btnY = EXIT_BTN_PADDING
    love.graphics.setColor(0.9, 0.2, 0.2, self.exitBtnHovered and 1 or 0.8)
    love.graphics.rectangle("fill", btnX, btnY, EXIT_BTN_SIZE, EXIT_BTN_SIZE, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        btnX + 10, btnY + 10, btnX + EXIT_BTN_SIZE - 10, btnY + EXIT_BTN_SIZE - 10
    )
    love.graphics.line(
        btnX + EXIT_BTN_SIZE - 10, btnY + 10, btnX + 10, btnY + EXIT_BTN_SIZE - 10
    )
    love.graphics.setLineWidth(1)

    -- Draw next review message if present
    if self.nextReviewMessage then
        love.graphics.setFont(self.streakFont)
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        local textWidth = self.streakFont:getWidth(self.nextReviewMessage)
        -- Align vertically with streak text (y = 20)
        love.graphics.print(self.nextReviewMessage, (love.graphics.getWidth() - textWidth) / 2, 20)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw group count in lower right corner
    if self.dueGroups and #self.dueGroups > 0 then
        local groupText = string.format("%d/%d", math.min(self.currentIndex, #self.dueGroups), #self.dueGroups)
        love.graphics.setFont(self.streakFont)
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local textWidth = self.streakFont:getWidth(groupText)
        local textHeight = self.streakFont:getHeight()
        love.graphics.print(groupText, love.graphics.getWidth() - textWidth - 20,
            love.graphics.getHeight() - textHeight - 20)
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw group SRS level in lower left corner
    if self.dueGroups and #self.dueGroups > 0 and self.srsStates then
        local groupIdx = math.min(self.currentIndex, #self.dueGroups)
        local dueGroup = self.dueGroups[groupIdx]
        if dueGroup and dueGroup.group then
            -- Find the minimum SRS level (n) among all kanji in the group (show lowest level)
            local minLevel = nil
            for _, kanji in ipairs(dueGroup.group) do
                local state = self.srsStates[kanji.character]
                if state and state.n ~= nil then
                    if not minLevel or state.n < minLevel then
                        minLevel = state.n
                    end
                else
                    minLevel = 0
                    break
                end
            end
            minLevel = minLevel or 0
            local levelText = string.format("Level: %d", minLevel)
            love.graphics.setFont(self.streakFont)
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.print(levelText, 20, love.graphics.getHeight() - self.streakFont:getHeight() - 20)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    -- Draw all confetti
    self.confettiCannon:draw()
end

-- Show next review time for the just-finished group for a few seconds
function GameScene:showNextReviewTimeForCurrentGroup()
    -- Find the group that was just finished
    local groupIdx = self.currentIndex
    if groupIdx > #self.dueGroups then
        groupIdx = #self.dueGroups
    end
    local dueGroup = self.dueGroups[groupIdx]
    if not dueGroup or not dueGroup.group then
        return
    end

    -- Find the latest nextReview timestamp among all kanji in the group
    local maxNextReview = 0
    for _, kanji in ipairs(dueGroup.group) do
        local state = self.srsStates[kanji.character]
        if state and state.nextReview and state.nextReview > maxNextReview then
            maxNextReview = state.nextReview
        end
    end

    if maxNextReview > 0 then
        local now = os.time()
        local seconds = maxNextReview - now
        local minutes = math.floor(seconds / 60)
        local hours = math.floor(minutes / 60)
        local days = math.floor(hours / 24)
        local msg = ""
        if seconds < 60 then
            msg = "Next review for this group: less than a minute!"
        elseif minutes < 60 then
            msg = string.format("Next review for this group: in %d minute%s", minutes, minutes == 1 and "" or "s")
        elseif hours < 24 then
            msg = string.format("Next review for this group: in %d hour%s", hours, hours == 1 and "" or "s")
        else
            msg = string.format("Next review for this group: in %d day%s", days, days == 1 and "" or "s")
        end
        self.nextReviewMessage = msg
        self.nextReviewMessageTimer = 3.0 -- Show for 3 seconds
    end
end

function GameScene:update(dt)
    -- Update all confetti particles
    self.confettiCannon:update(dt)

    -- Update next review message timer
    if self.nextReviewMessage then
        self.nextReviewMessageTimer = self.nextReviewMessageTimer - dt
        if self.nextReviewMessageTimer <= 0 then
            self.nextReviewMessage = nil
            self.nextReviewMessageTimer = 0
        end
    end

    -- Auto-save SRS states periodically
    self:autoSaveSRSStates()
end

function GameScene:mousemoved(x, y, dx, dy, istouch)
    assert(type(x) == "number", "Mouse x coordinate must be a number")
    assert(type(y) == "number", "Mouse y coordinate must be a number")

    -- Check if mouse is over exit button
    local btnX = EXIT_BTN_PADDING
    local btnY = EXIT_BTN_PADDING
    if x >= btnX and x <= btnX + EXIT_BTN_SIZE and y >= btnY and y <= btnY + EXIT_BTN_SIZE then
        self.exitBtnHovered = true
    else
        self.exitBtnHovered = false
    end

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
    assert(type(x) == "number", "Mouse x coordinate must be a number")
    assert(type(y) == "number", "Mouse y coordinate must be a number")
    assert(type(button) == "number", "Mouse button must be a number")

    -- Check if exit button was clicked
    local btnX = EXIT_BTN_PADDING
    local btnY = EXIT_BTN_PADDING
    if x >= btnX and x <= btnX + EXIT_BTN_SIZE and y >= btnY and y <= btnY + EXIT_BTN_SIZE and button == 1 then
        -- Exit/cancel: finalize session and go to overview scene
        self.sessionTracker:finalizeSession()
        SCENE_MANAGER:switchTo(SCENES.gameOverviewScene, self.sessionTracker:getStats())
        return
    end

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
