local utf8 = require("utf8")
local BaseScene = require("scenes.baseScene")
local WaniKani = require("objects.wanikani")
local roundRect = require("libs.roundRect")

--- Cleans up the API token by removing unnecessary whitespace.
--- @param token string The API token string to clean.
--- @return string The cleaned API token string.
local function cleanToken(token)
    -- Remove spaces, tabs, newlines, carriage returns, and other common whitespace
    return (token:gsub("[%s\r\n]", ""))
end


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

    -- Error handling state
    self.showError = false
    self.errorMessage = ""
    self.errorTimer = 0

    -- Setup error dialog
    local width, height = love.graphics.getDimensions()
    local centerX = width / 2
    local centerY = height / 2

    self.errorDialog = {
        width = 500,
        height = 200,
        x = centerX - 250,
        y = centerY - 25,
        okButton = {
            x = centerX - 50,
            y = centerY + 100,
            width = 100,
            height = 40,
            hovered = false
        }
    }
end

-- Called when the scene is no longer the active scene.
-- Use this for cleanup before switching to another scene.
function WelcomeScene:leave()
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

    -- Handle error dialog auto-close
    if self.showError then
        self.errorTimer = self.errorTimer + dt
        -- Auto-hide error after 30 seconds
        if self.errorTimer > 30 then
            self.showError = false
            self.errorTimer = 0
        end
    end
end

function WelcomeScene:textinput(t)
    -- Only handle text input if error dialog is not shown
    if not self.showError then
        -- Limit API token input to 36 characters
        if utf8.len(self.text) < self.maxTextLength then
            self.text = self.text .. t
        end
    end
end

function WelcomeScene:keypressed(key)
    -- Handle error dialog first
    if self.showError then
        if key == "return" or key == "enter" or key == "escape" then
            self.showError = false
            self.errorTimer = 0
        end
        return
    end

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
        -- Validate input first
        local cleanedToken = cleanToken(self.text)
        if cleanedToken == "" or utf8.len(cleanedToken) < 10 then
            self:showErrorMessage("Please enter a valid API token (at least 10 characters)")
            return
        end

        local wanikani = WaniKani:new(cleanedToken)
        wanikani:getUserInfo(function(success, userInfo)
            if success then
                -- Check if subscription is active
                if not userInfo.subscription.active then
                    self:showErrorMessage(
                        "Your WaniKani subscription is not active.\nPlease activate your subscription to use this app.")
                    return
                end

                SETTINGS.isValidToken = true
                SETTINGS.apiToken = cleanedToken
                SETTINGS.userLevel = userInfo.level
                SETTINGS.activeSubscription = userInfo.subscription.active
                SETTINGS.maxGrantedLevel = userInfo.subscription.max_level_granted
                SETTINGS:save()

                wanikani:fetchKanjiData(SETTINGS.maxGrantedLevel, "kanjiData.json", function(success, result)
                    if not success then
                        self:showErrorMessage("Failed to fetch kanji data from WaniKani.\nError: " ..
                            (result or "Unknown error") .. "\n\nPlease check your internet connection and try again.")
                    else
                        -- Switch to the main menu scene after successful data fetch
                        SCENE_MANAGER:switchTo(SCENES.mainMenuScene)
                    end
                end)
            else
                -- Handle API token validation error
                SETTINGS.isValidToken = false
                local errorMsg = "Failed to validate API token.\n"
                if userInfo and type(userInfo) == "string" then
                    errorMsg = errorMsg .. "Error: " .. userInfo
                else
                    errorMsg = errorMsg .. "Please check that your token is correct."
                end
                errorMsg = errorMsg .. "\n\nMake sure you have a valid WaniKani API token."
                self:showErrorMessage(errorMsg)
            end
        end)
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

    -- Draw error dialog if shown
    if self.showError then
        self:drawErrorDialog()
    end
end

function WelcomeScene:mousemoved(x, y, dx, dy, istouch)
    if self.showError then
        -- Update OK button hover state
        local okBtn = self.errorDialog.okButton
        okBtn.hovered = x >= okBtn.x and x <= okBtn.x + okBtn.width and
            y >= okBtn.y and y <= okBtn.y + okBtn.height
    end
end

function WelcomeScene:mousepressed(x, y, button, istouch, presses)
    if button == 1 and self.showError then -- Left mouse button
        if self.errorDialog.okButton.hovered then
            self.showError = false
            self.errorTimer = 0
        end
    end
end

function WelcomeScene:showErrorMessage(message)
    self.errorMessage = message
    self.showError = true
    self.errorTimer = 0
end

function WelcomeScene:drawErrorDialog()
    local dialog = self.errorDialog

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Error dialog background
    love.graphics.setColor(0.4, 0.3, 0.3, 1)
    roundRect("fill", dialog.x, dialog.y, dialog.width, dialog.height, 12, 12)
    love.graphics.setColor(0.8, 0.6, 0.6, 1)
    roundRect("line", dialog.x, dialog.y, dialog.width, dialog.height, 12, 12)

    -- Error title
    love.graphics.setColor(1, 0.8, 0.8, 1)
    local titleFont = love.graphics.newFont(SETTINGS.font, 24)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Error", dialog.x, dialog.y + 20, dialog.width, "center")

    -- Error message
    love.graphics.setColor(1, 1, 1, 1)
    local messageFont = love.graphics.newFont(SETTINGS.font, 16)
    love.graphics.setFont(messageFont)
    love.graphics.printf(self.errorMessage, dialog.x + 20, dialog.y + 60, dialog.width - 40, "center")

    -- OK button
    local okBtn = dialog.okButton
    love.graphics.setColor(okBtn.hovered and 0.7 or 0.5, okBtn.hovered and 0.7 or 0.5, okBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", okBtn.x, okBtn.y, okBtn.width, okBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", okBtn.x, okBtn.y, okBtn.width, okBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    local buttonFont = love.graphics.newFont(SETTINGS.font, 18)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("OK", okBtn.x, okBtn.y + okBtn.height / 2 - buttonFont:getHeight() / 2, okBtn.width, "center")

    -- Instructions
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    local instructFont = love.graphics.newFont(SETTINGS.font, 14)
    love.graphics.setFont(instructFont)
    love.graphics.printf("Press Enter, Escape, or click OK to close", dialog.x, dialog.y + dialog.height - 30,
        dialog.width, "center")
end

-- Return the scene object so it can be registered by the SceneManager
return WelcomeScene
