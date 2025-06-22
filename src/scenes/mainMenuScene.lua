local BaseScene = require("scenes.baseScene")
local roundRect = require("libs.roundRect")

local MainMenuScene = BaseScene:new()
MainMenuScene.__index = MainMenuScene

-- Called once when the scene is first loaded.
function MainMenuScene:load()
end

-- Called when the scene becomes the active scene.
function MainMenuScene:enter(...)
    -- Button properties
    self.buttonWidth = 300
    self.buttonHeight = 60
    self.buttonSpacing = 20

    -- Calculate button positions
    local width, height = love.graphics.getDimensions()
    local centerX = width / 2
    local startY = height * 0.4

    self.buttons = {
        reviews = {
            x = centerX - self.buttonWidth / 2,
            y = startY,
            width = self.buttonWidth,
            height = self.buttonHeight,
            text = "Reviews (" .. SETTINGS.groupsPerLesson .. ")",
            hovered = false
        },
        settings = {
            x = centerX - self.buttonWidth / 2,
            y = startY + self.buttonHeight + self.buttonSpacing,
            width = self.buttonWidth,
            height = self.buttonHeight,
            text = "Settings",
            hovered = false
        }
    }
end

function MainMenuScene:mousemoved(x, y, dx, dy, istouch)
    -- Update button hover states
    for _, button in pairs(self.buttons) do
        button.hovered = x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height
    end
end

-- Handle mouse clicks
function MainMenuScene:mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        -- Check Reviews button
        if self.buttons.reviews.hovered then
            SCENE_MANAGER:switchTo(SCENES.gameScene)
            -- Check Settings button
        elseif self.buttons.settings.hovered then
            SCENE_MANAGER:switchTo(SCENES.settingsScene)
        end
    end
end

-- Called every frame to draw the scene.
function MainMenuScene:draw()
    local width, height = love.graphics.getDimensions()

    -- Title
    local titleFont = love.graphics.newFont(SETTINGS.font, 48)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1) -- White color for text
    love.graphics.printf("Kanji Match", 0, height * 0.15, width, "center")

    -- Button font
    local buttonFont = love.graphics.newFont(SETTINGS.font, 24)
    love.graphics.setFont(buttonFont)

    -- Draw buttons
    for _, button in pairs(self.buttons) do
        -- Button background color based on hover state
        if button.hovered then
            love.graphics.setColor(0.7, 0.7, 0.9, 1) -- Light blue when hovered
        else
            love.graphics.setColor(0.5, 0.5, 0.7, 1) -- Default blue-gray
        end

        -- Draw button background
        roundRect("fill", button.x, button.y, button.width, button.height, 12, 12)

        -- Button border
        love.graphics.setColor(0.3, 0.3, 0.5, 1) -- Darker border
        roundRect("line", button.x, button.y, button.width, button.height, 12, 12)

        -- Button text
        love.graphics.setColor(1, 1, 1, 1) -- White text
        love.graphics.printf(button.text, button.x, button.y + button.height / 2 - buttonFont:getHeight() / 2,
            button.width, "center")
    end
end

-- Return the scene object so it can be registered by the SceneManager
return MainMenuScene
