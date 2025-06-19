---@diagnostic disable: duplicate-set-field
local utf8 = require("utf8")
local BaseScene = require("scenes.baseScene")

-- Create a new scene object, inheriting from BaseScene
local TextInputExampleScene = BaseScene:new()
TextInputExampleScene.__index = TextInputExampleScene

-- Called once when the scene is first loaded.
function TextInputExampleScene:load()
    self.text = "Type away! -- "
    self.cursor = ""
    self.cursorTimer = 0

    -- Important to enable text input handling
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)

    -- UI elements
    self.titleFont = love.graphics.newFont(24)
    self.inputFont = love.graphics.newFont(18)
    self.instructionFont = love.graphics.newFont(16)

    -- Colors
    self.colors = {
        background = { 0.1, 0.1, 0.2, 1 },
        white = { 1, 1, 1, 1 },
        blue = { 0.3, 0.3, 0.8, 1 },
        gray = { 0.5, 0.5, 0.5, 1 }
    }
end

function TextInputExampleScene:update(dt)
    -- Animate cursor blinking
    self.cursorTimer = self.cursorTimer + dt
    if self.cursorTimer > 1.0 then
        self.cursorTimer = 0
        self.cursor = self.cursor == "|" and "" or "|"
    end
end

function TextInputExampleScene:textinput(t)
    print("Received text input: '" .. t .. "' (length: " .. utf8.len(t) .. ")")
    self.text = self.text .. t
end

function TextInputExampleScene:keypressed(key)
    print("Key pressed: '" .. key .. "'")
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(self.text, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            self.text = string.sub(self.text, 1, byteoffset - 1)
        end
    elseif key == "return" or key == "enter" then
        -- Add a line break
        self.text = self.text .. "\n"
    elseif key == "escape" then
        -- Return to main game
        if SCENE_MANAGER then
            SCENE_MANAGER:switchTo("InitialScene")
        end
    elseif key == "c" and love.keyboard.isDown("lctrl") then
        -- Clear text (Ctrl+C)
        self.text = "Type away! -- "
    end
end

function TextInputExampleScene:keyreleased(key, scancode)
    -- Reset key repeat when returning to main game
    if key == "escape" then
        love.keyboard.setKeyRepeat(false)
    end
end

-- Called every frame to draw the scene.
function TextInputExampleScene:draw()
    -- Background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    local y = 50

    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(self.colors.white)
    local title = "Text Input Example"
    local titleWidth = self.titleFont:getWidth(title)
    love.graphics.print(title, (love.graphics.getWidth() - titleWidth) / 2, y)
    y = y + 50

    -- Instructions
    love.graphics.setFont(self.instructionFont)
    love.graphics.setColor(self.colors.blue)
    love.graphics.print("Instructions:", 50, y)
    y = y + 25
    love.graphics.setColor(self.colors.white)
    love.graphics.print("• Type anything to add text", 50, y)
    y = y + 20
    love.graphics.print("• Press BACKSPACE to delete characters", 50, y)
    y = y + 20
    love.graphics.print("• Press ENTER for new lines", 50, y)
    y = y + 20
    love.graphics.print("• Press CTRL+C to clear text", 50, y)
    y = y + 20
    love.graphics.print("• Press ESC to return to main game", 50, y)
    y = y + 40

    -- Text input area background
    love.graphics.setColor(self.colors.gray)
    love.graphics.rectangle("line", 50, y, love.graphics.getWidth() - 100, love.graphics.getHeight() - y - 50)

    -- Text content
    love.graphics.setFont(self.inputFont)
    love.graphics.setColor(self.colors.white)

    -- Draw the text with cursor
    local displayText = self.text .. self.cursor
    love.graphics.printf(displayText, 60, y + 10, love.graphics.getWidth() - 120)

    -- Character count
    local charCount = utf8.len(self.text)
    love.graphics.setFont(self.instructionFont)
    love.graphics.setColor(self.colors.gray)
    love.graphics.print("Characters: " .. (charCount or 0), love.graphics.getWidth() - 150,
        love.graphics.getHeight() - 30)

    -- Reset color
    love.graphics.setColor(self.colors.white)
end

-- Return the scene object so it can be registered by the SceneManager
return TextInputExampleScene
