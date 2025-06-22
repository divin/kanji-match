local BaseScene = require("scenes.baseScene")

local GameOverviewScene = BaseScene:new()
GameOverviewScene.__index = GameOverviewScene

-- Called once when the scene is first loaded.
function GameOverviewScene:load()
    -- Initialize stats variables
    self.totalGroups = 0
    self.completedGroups = 0
    self.totalKanji = 0
    self.correctMatches = 0
    self.incorrectMatches = 0
    self.streak = 0
    self.sessionTime = 0
end

-- Called when the scene becomes the active scene.
function GameOverviewScene:enter(stats)
    -- Accept stats from the game scene
    if stats then
        self.totalGroups = stats.totalGroups or 0
        self.completedGroups = stats.completedGroups or 0
        self.totalKanji = stats.totalKanji or 0
        self.correctMatches = stats.correctMatches or 0
        self.incorrectMatches = stats.incorrectMatches or 0
        self.streak = stats.maxStreak or 0
        self.sessionTime = stats.sessionTime or 0
    end
end

-- Called when the scene is no longer the active scene.
function GameOverviewScene:leave()
end

function GameOverviewScene:update(dt)
end

-- Handle key presses
function GameOverviewScene:keypressed(key)
    if key == "space" or key == "return" or key == "enter" then
        -- Return to main menu
        SCENE_MANAGER:switchTo(SCENES.mainMenuScene)
    end
end

-- Handle mouse clicks
function GameOverviewScene:mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        -- Return to main menu on any click
        SCENE_MANAGER:switchTo(SCENES.mainMenuScene)
    end
end

-- Called every frame to draw the scene.
function GameOverviewScene:draw()
    local width, height = love.graphics.getDimensions()

    -- Fonts
    local titleFont = love.graphics.newFont(SETTINGS.font, 36)
    local statsFont = love.graphics.newFont(SETTINGS.font, 24)
    local instructionFont = love.graphics.newFont(SETTINGS.font, 18)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1) -- White color
    love.graphics.printf("Review Session Complete!", 0, height * 0.1, width, "center")

    -- Stats display
    love.graphics.setFont(statsFont)
    local startY = height * 0.25
    local lineHeight = 40

    -- Calculate accuracy
    local totalAttempts = self.correctMatches + self.incorrectMatches
    local accuracy = totalAttempts > 0 and (self.correctMatches / totalAttempts * 100) or 0

    -- Format session time
    local minutes = math.floor(self.sessionTime / 60)
    local seconds = math.floor(self.sessionTime % 60)
    local timeString = string.format("%d:%02d", minutes, seconds)

    -- Display stats
    local stats = {
        "Groups Completed: " .. self.completedGroups .. "/" .. self.totalGroups,
        "Total Kanji Reviewed: " .. self.totalKanji,
        "Correct Matches: " .. self.correctMatches,
        "Incorrect Matches: " .. self.incorrectMatches,
        "Accuracy: " .. string.format("%.1f%%", accuracy),
        "Best Streak: " .. self.streak,
        "Session Time: " .. timeString
    }

    for i, stat in ipairs(stats) do
        love.graphics.printf(stat, 0, startY + (i - 1) * lineHeight, width, "center")
    end

    -- Instructions
    love.graphics.setFont(instructionFont)
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.printf("Press SPACE or click anywhere to return to main menu", 0, height * 0.85, width, "center")
end

-- Return the scene object so it can be registered by the SceneManager
return GameOverviewScene
