local BaseScene = require("scenes.baseScene")

-- Create a new scene object, inheriting from BaseScene
local FontExampleScene = BaseScene:new()
FontExampleScene.__index = FontExampleScene -- For proper method lookup if methods are added after new()

-- Called once when the scene is first loaded.
function FontExampleScene:load()
    self.exampleText = "Kanji Match ありがとう　カンジ　漢字"
    self.fontKeys = {}
    for key, _ in pairs(FONTS) do
        table.insert(self.fontKeys, key)
    end

    self.currentIndex = 1
    self.fontKey = self.fontKeys[self.currentIndex]

    self.defaultFont = love.graphics.getFont()
    self.currentFont = love.graphics.newFont(FONTS[self.fontKey], 40)
end

-- Called every frame to draw the scene.
function FontExampleScene:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw Example Text
    love.graphics.setFont(self.currentFont)
    love.graphics.printf(self.exampleText, 0, screenHeight / 2 - 70, screenWidth, "center")

    -- Draw Current Font Name
    love.graphics.setFont(self.defaultFont)
    love.graphics.printf(self.fontKey, 0, screenHeight / 2 + 30, screenWidth, "center")
end

-- Example of overriding a specific input callback
function FontExampleScene:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit() -- Quit the game if Escape is pressed on the title screen
    end
end

function FontExampleScene:keyreleased(key, scancode)
    if key == "left" then
        -- Switch to the previous font
        self.currentIndex = self.currentIndex - 1
        if self.currentIndex < 1 then
            self.currentIndex = #self.fontKeys
        end
    end

    if key == "right" then
        -- Switch to the next font
        self.currentIndex = self.currentIndex + 1
        if self.currentIndex > #self.fontKeys then
            self.currentIndex = 1
        end
    end

    self.fontKey = self.fontKeys[self.currentIndex]
    self.currentFont = love.graphics.newFont(FONTS[self.fontKey], 40)
end

-- Return the scene object so it can be registered by the SceneManager
return FontExampleScene
