local utf8 = require("utf8")
local BaseScene = require("scenes.baseScene")
local WaniKani = require("objects.wanikani")
local roundRect = require("libs.roundRect")


local WelcomeScene = BaseScene:new()
WelcomeScene.__index = WelcomeScene

-- Called once when the scene is first loaded.
function WelcomeScene:load()
end

-- Called when the scene becomes the active scene.
function WelcomeScene:enter(...)
    -- Important to enable text input handling
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)

    -- Initialize cursor and timer for blinking effect
    self.cursor = ""
    self.cursorTimer = 0

    -- Initialize text input for the API Token
    self.text = ""
    self.maxTextLength = 36 -- Maximum length for the API Token input
end

-- Called when the scene is no longer the active scene.
-- Use this for cleanup before switching to another scene.
function BaseScene:leave()
    -- Turn off text input handling
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)
end

function WelcomeScene:update(dt)
    -- Animate cursor blinking
    self.cursorTimer = self.cursorTimer + dt
    if self.cursorTimer > 1.0 then
        self.cursorTimer = 0
        self.cursor = self.cursor == "|" and "" or "|"
    end
end

function WelcomeScene:textinput(t)
    -- Limit API token input to 36 characters
    if utf8.len(self.text) < self.maxTextLength then
        self.text = self.text .. t
    end
end

function WelcomeScene:keypressed(key)
    local control = false
    local osString = love.system.getOS()

    if osString == "OS X" then
        -- Use type annotation to suppress language server warnings
        ---@diagnostic disable-next-line: param-type-mismatch
        control = love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui")
    elseif osString == "Windows" or osString == "Linux" then
        -- Use type annotation to suppress language server warnings
        ---@diagnostic disable-next-line: param-type-mismatch
        control = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    end

    if key == "backspace" then
        -- Get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(self.text, -1)

        if byteoffset then
            -- Remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            self.text = string.sub(self.text, 1, byteoffset - 1)
        end
    elseif control then
        if key == "c" then
            love.system.setClipboardText(self.text)
        end
        if key == "v" then
            local clipboardText = love.system.getClipboardText()
            local clipboardLength = utf8.len(clipboardText)

            if clipboardLength <= self.maxTextLength then
                -- Replace with the entire clipboard text
                self.text = clipboardText
            else
                -- Replace with truncated clipboard text to fit within the limit
                local truncatedText = string.sub(clipboardText, 1,
                    utf8.offset(clipboardText, self.maxTextLength + 1) - 1)
                self.text = truncatedText
            end
        end
    elseif key == "return" or key == "enter" then
        local wanikani = WaniKani:new(self.text)
        wanikani:getUserInfo(function(success, userInfo)
            if success then
                SETTINGS.isValidToken = true
                SETTINGS.apiToken = self.text
                SETTINGS.userLevel = userInfo.level
                SETTINGS.activeSubscription = userInfo.subscription.active
                SETTINGS.maxGrantedLevel = userInfo.subscription.max_level_granted
                SETTINGS:save()

                wanikani:fetchKanjiData(SETTINGS.maxGrantedLevel, "kanjiData.json", function(success, result)
                    if not success then
                        -- TODO: Handle error gracefully, e.g., show a message to the user
                        print("Failed to fetch kanji data: " .. (result or "Unknown error"))
                    end
                end)
            else
                -- TODO: Handle error gracefully, e.g., show a message to the user
                SETTINGS.isValidToken = false
                print("Failed to get user info: " .. (userInfo or "Unknown error"))
            end
        end)
        -- TODO: Switch to the main game scene after successful validation
        -- TODO: Show error message if some error occurs
    end
end

-- Called every frame to draw the scene.
function WelcomeScene:draw()
    local width, height = love.graphics.getDimensions()

    -- Fonts
    local titleFont = love.graphics.newFont(SETTINGS.font, 36)
    local descriptionFont = love.graphics.newFont(SETTINGS.font, 20)
    local inputFont = love.graphics.newFont(SETTINGS.font, 18)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1) -- White color for text
    love.graphics.printf("Welcome to Kanji Match!", 0, height * 0.1, width, "center")

    -- Description
    love.graphics.setFont(descriptionFont)
    love.graphics.printf("Please enter your API Token to get started:", 0, height * 0.2, width, "center")

    -- Input field
    love.graphics.setFont(inputFont)
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray background for input
    roundRect("fill", width * 0.25, height * 0.3, width * 0.5, 40, 12, 12)
    love.graphics.setColor(0, 0, 0, 1)       -- Black color for text
    love.graphics.print(self.text .. self.cursor, width * 0.26, height * 0.3 + 10)
    love.graphics.setColor(1, 1, 1, 1)       -- Reset color to white for any further drawing

    -- Instructions
    love.graphics.setFont(descriptionFont)
    love.graphics.printf("Press Enter to submit.", 0, height * 0.4, width, "center")
    love.graphics.printf("Valid API Token: " .. (SETTINGS.isValidToken and "Yes" or "No"), 0, height * 0.45, width,
        "center")
    love.graphics.printf("Active Subscription: " .. (SETTINGS.activeSubscription and "Yes" or "No"), 0, height * 0.5,
        width,
        "center")
    love.graphics.printf("User Level: " .. (SETTINGS.userLevel or "N/A"), 0, height * 0.55, width, "center")
    love.graphics.printf("Max Granted Level: " .. (SETTINGS.maxGrantedLevel or "N/A"), 0, height * 0.6, width, "center")
    love.graphics.printf("Kanji Data Loaded: " .. (love.filesystem.getInfo("kanjiData.json") and "Yes" or "No"), 0,
        height * 0.65, width,
        "center")
end

-- Return the scene object so it can be registered by the SceneManager
return WelcomeScene
