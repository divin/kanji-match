local BaseScene = require("scenes.baseScene")
local roundRect = require("libs.roundRect")

local SettingsScene = BaseScene:new()
SettingsScene.__index = SettingsScene

-- Called once when the scene is first loaded.
function SettingsScene:load()
    -- Button properties
    self.buttonWidth = 350
    self.buttonHeight = 60
    self.buttonSpacing = 20
    self.smallButtonWidth = 40
    self.smallButtonHeight = 40

    -- Calculate positions
    local width, height = love.graphics.getDimensions()
    local centerX = width / 2
    local startY = height * 0.2

    -- Font options
    self.fontOptions = {
        { name = "Gothic",  value = FONTS.gothic },
        { name = "Keifont", value = FONTS.keifont },
        { name = "Sanafon", value = FONTS.sanafon }
    }

    -- Find current font index
    self.currentFontIndex = 1
    for i, font in ipairs(self.fontOptions) do
        if font.value == SETTINGS.font then
            self.currentFontIndex = i
            break
        end
    end

    -- Reset confirmation state
    self.showResetWarning = false
    self.resetWarningTimer = 0

    -- Initialize UI elements
    self:setupButtons(centerX, startY)
end

function SettingsScene:setupButtons(centerX, startY)
    local yOffset = 0

    -- Groups per lesson setting
    self.groupsSection = {
        y = startY + yOffset,
        minusButton = {
            x = centerX - 180,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        },
        plusButton = {
            x = centerX + 140,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        }
    }
    yOffset = yOffset + self.buttonHeight + self.buttonSpacing

    -- Font setting
    self.fontSection = {
        y = startY + yOffset,
        prevButton = {
            x = centerX - 180,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        },
        nextButton = {
            x = centerX + 140,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        }
    }
    yOffset = yOffset + self.buttonHeight + self.buttonSpacing * 2

    -- Sound Effect Volume setting
    self.soundSection = {
        y = startY + yOffset,
        minusButton = {
            x = centerX - 180,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        },
        plusButton = {
            x = centerX + 140,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        }
    }
    yOffset = yOffset + self.buttonHeight + self.buttonSpacing

    -- Confetti Amount setting
    self.confettiSection = {
        y = startY + yOffset,
        minusButton = {
            x = centerX - 180,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        },
        plusButton = {
            x = centerX + 140,
            y = startY + yOffset,
            width = self.smallButtonWidth,
            height = self.smallButtonHeight,
            hovered = false
        }
    }
    yOffset = yOffset + self.buttonHeight + self.buttonSpacing

    -- Reset data button
    self.resetButton = {
        x = centerX - self.buttonWidth / 2,
        y = startY + yOffset,
        width = self.buttonWidth,
        height = self.buttonHeight,
        hovered = false
    }
    yOffset = yOffset + self.buttonHeight + self.buttonSpacing

    -- Back button
    self.backButton = {
        x = centerX - self.buttonWidth / 2,
        y = startY + yOffset + self.buttonSpacing,
        width = self.buttonWidth,
        height = self.buttonHeight,
        hovered = false
    }

    -- Reset warning dialog
    self.warningDialog = {
        width = 500,
        height = 250,
        x = centerX - 250,
        y = startY + 50,
        confirmButton = {
            x = centerX - 120,
            y = startY + 250,
            width = 100,
            height = 40,
            hovered = false
        },
        cancelButton = {
            x = centerX + 20,
            y = startY + 250,
            width = 100,
            height = 40,
            hovered = false
        }
    }
end

-- Called when the scene becomes the active scene.
function SettingsScene:enter(...)
    -- Reset warning state when entering
    self.showResetWarning = false
    self.resetWarningTimer = 0
end

-- Called when the scene is no longer the active scene.
function SettingsScene:leave()
end

function SettingsScene:update(dt)
    if self.showResetWarning then
        self.resetWarningTimer = self.resetWarningTimer + dt
        -- Auto-hide warning after 30 seconds
        if self.resetWarningTimer > 30 then
            self.showResetWarning = false
            self.resetWarningTimer = 0
        end
    end
end

function SettingsScene:mousemoved(x, y, dx, dy, istouch)
    if self.showResetWarning then
        -- Only check warning dialog buttons when warning is shown
        local dialog = self.warningDialog
        dialog.confirmButton.hovered = x >= dialog.confirmButton.x and
            x <= dialog.confirmButton.x + dialog.confirmButton.width and
            y >= dialog.confirmButton.y and y <= dialog.confirmButton.y + dialog.confirmButton.height
        dialog.cancelButton.hovered = x >= dialog.cancelButton.x and
            x <= dialog.cancelButton.x + dialog.cancelButton.width and
            y >= dialog.cancelButton.y and y <= dialog.cancelButton.y + dialog.cancelButton.height
    else
        -- Update button hover states
        local groups = self.groupsSection
        groups.minusButton.hovered = x >= groups.minusButton.x and x <= groups.minusButton.x + groups.minusButton.width and
            y >= groups.minusButton.y and y <= groups.minusButton.y + groups.minusButton.height
        groups.plusButton.hovered = x >= groups.plusButton.x and x <= groups.plusButton.x + groups.plusButton.width and
            y >= groups.plusButton.y and y <= groups.plusButton.y + groups.plusButton.height

        local font = self.fontSection
        font.prevButton.hovered = x >= font.prevButton.x and x <= font.prevButton.x + font.prevButton.width and
            y >= font.prevButton.y and y <= font.prevButton.y + font.prevButton.height
        font.nextButton.hovered = x >= font.nextButton.x and x <= font.nextButton.x + font.nextButton.width and
            y >= font.nextButton.y and y <= font.nextButton.y + font.nextButton.height

        local sound = self.soundSection
        sound.minusButton.hovered = x >= sound.minusButton.x and x <= sound.minusButton.x + sound.minusButton.width and
            y >= sound.minusButton.y and y <= sound.minusButton.y + sound.minusButton.height
        sound.plusButton.hovered = x >= sound.plusButton.x and x <= sound.plusButton.x + sound.plusButton.width and
            y >= sound.plusButton.y and y <= sound.plusButton.y + sound.plusButton.height

        local confetti = self.confettiSection
        confetti.minusButton.hovered = x >= confetti.minusButton.x and
            x <= confetti.minusButton.x + confetti.minusButton.width and
            y >= confetti.minusButton.y and y <= confetti.minusButton.y + confetti.minusButton.height
        confetti.plusButton.hovered = x >= confetti.plusButton.x and
            x <= confetti.plusButton.x + confetti.plusButton.width and
            y >= confetti.plusButton.y and y <= confetti.plusButton.y + confetti.plusButton.height

        self.resetButton.hovered = x >= self.resetButton.x and x <= self.resetButton.x + self.resetButton.width and
            y >= self.resetButton.y and y <= self.resetButton.y + self.resetButton.height

        self.backButton.hovered = x >= self.backButton.x and x <= self.backButton.x + self.backButton.width and
            y >= self.backButton.y and y <= self.backButton.y + self.backButton.height
    end
end

function SettingsScene:mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        if self.showResetWarning then
            -- Handle warning dialog buttons
            if self.warningDialog.confirmButton.hovered then
                self:resetAllData()
            elseif self.warningDialog.cancelButton.hovered then
                self.showResetWarning = false
                self.resetWarningTimer = 0
            end
        else
            -- Handle main settings buttons
            if self.groupsSection.minusButton.hovered then
                self:decreaseGroupsPerLesson()
            elseif self.groupsSection.plusButton.hovered then
                self:increaseGroupsPerLesson()
            elseif self.fontSection.prevButton.hovered then
                self:previousFont()
            elseif self.fontSection.nextButton.hovered then
                self:nextFont()
            elseif self.soundSection.minusButton.hovered then
                SETTINGS.soundEffectVolume = math.max(0, (SETTINGS.soundEffectVolume or 0) - 1)
                SETTINGS:save()
            elseif self.soundSection.plusButton.hovered then
                SETTINGS.soundEffectVolume = math.min(10, (SETTINGS.soundEffectVolume or 0) + 1)
                SETTINGS:save()
            elseif self.confettiSection.minusButton.hovered then
                SETTINGS.confettiAmount = math.max(0, (SETTINGS.confettiAmount or 0) - 5)
                SETTINGS:save()
            elseif self.confettiSection.plusButton.hovered then
                SETTINGS.confettiAmount = math.min(100, (SETTINGS.confettiAmount or 0) + 5)
                SETTINGS:save()
            elseif self.resetButton.hovered then
                self:showResetConfirmation()
            elseif self.backButton.hovered then
                SCENE_MANAGER:switchTo(SCENES.mainMenuScene)
            end
        end
    end
end

function SettingsScene:decreaseGroupsPerLesson()
    if SETTINGS.groupsPerLesson > 5 then
        SETTINGS.groupsPerLesson = SETTINGS.groupsPerLesson - 1
        SETTINGS:save()
    end
end

function SettingsScene:increaseGroupsPerLesson()
    SETTINGS.groupsPerLesson = SETTINGS.groupsPerLesson + 1
    SETTINGS:save()
end

function SettingsScene:previousFont()
    self.currentFontIndex = self.currentFontIndex - 1
    if self.currentFontIndex < 1 then
        self.currentFontIndex = #self.fontOptions
    end
    SETTINGS.font = self.fontOptions[self.currentFontIndex].value
    SETTINGS:save()
end

function SettingsScene:nextFont()
    self.currentFontIndex = self.currentFontIndex + 1
    if self.currentFontIndex > #self.fontOptions then
        self.currentFontIndex = 1
    end
    SETTINGS.font = self.fontOptions[self.currentFontIndex].value
    SETTINGS:save()
end

function SettingsScene:showResetConfirmation()
    self.showResetWarning = true
    self.resetWarningTimer = 0
end

function SettingsScene:resetAllData()
    -- Delete kanji data file
    if love.filesystem.getInfo("kanjiData.json") then
        love.filesystem.remove("kanjiData.json")
    end

    -- Delete settings file
    if love.filesystem.getInfo("settings.json") then
        love.filesystem.remove("settings.json")
    end

    -- Reset settings to defaults
    SETTINGS.apiToken = ""
    SETTINGS.isValidToken = false
    SETTINGS.activeSubscription = false
    SETTINGS.userLevel = 1
    SETTINGS.maxGrantedLevel = 1
    SETTINGS.groupsPerLesson = 5
    SETTINGS.font = FONTS.keifont

    -- Hide warning and switch to welcome scene
    self.showResetWarning = false
    SCENE_MANAGER:switchTo(SCENES.welcomeScene)
end

-- Called every frame to draw the scene.
function SettingsScene:draw()
    local width, height = love.graphics.getDimensions()

    -- Title
    local titleFont = love.graphics.newFont(SETTINGS.font, 48)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Settings", 0, height * 0.05, width, "center")

    -- Setting fonts
    local labelFont = love.graphics.newFont(SETTINGS.font, 24)
    local buttonFont = love.graphics.newFont(SETTINGS.font, 20)
    local smallButtonFont = love.graphics.newFont(SETTINGS.font, 18)

    if not self.showResetWarning then
        self:drawMainSettings(labelFont, buttonFont, smallButtonFont)
    else
        self:drawResetWarning(labelFont, buttonFont)
    end
end

function SettingsScene:drawMainSettings(labelFont, buttonFont, smallButtonFont)
    love.graphics.setFont(labelFont)

    -- Groups per lesson setting
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Groups per Lesson: " .. SETTINGS.groupsPerLesson, 0, self.groupsSection.y + 15,
        love.graphics.getWidth(), "center")

    -- Minus button
    local minusBtn = self.groupsSection.minusButton
    love.graphics.setColor(minusBtn.hovered and 0.7 or 0.5, minusBtn.hovered and 0.7 or 0.5,
        minusBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", minusBtn.x, minusBtn.y, minusBtn.width, minusBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", minusBtn.x, minusBtn.y, minusBtn.width, minusBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(smallButtonFont)
    love.graphics.printf("-", minusBtn.x, minusBtn.y + 8, minusBtn.width, "center")

    -- Plus button
    local plusBtn = self.groupsSection.plusButton
    love.graphics.setColor(plusBtn.hovered and 0.7 or 0.5, plusBtn.hovered and 0.7 or 0.5, plusBtn.hovered and 0.9 or 0.7,
        1)
    roundRect("fill", plusBtn.x, plusBtn.y, plusBtn.width, plusBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", plusBtn.x, plusBtn.y, plusBtn.width, plusBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("+", plusBtn.x, plusBtn.y + 8, plusBtn.width, "center")

    -- Font setting
    love.graphics.setFont(labelFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Font: " .. self.fontOptions[self.currentFontIndex].name, 0, self.fontSection.y + 15,
        love.graphics.getWidth(), "center")

    -- Previous font button
    local prevBtn = self.fontSection.prevButton
    love.graphics.setColor(prevBtn.hovered and 0.7 or 0.5, prevBtn.hovered and 0.7 or 0.5, prevBtn.hovered and 0.9 or 0.7,
        1)
    roundRect("fill", prevBtn.x, prevBtn.y, prevBtn.width, prevBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", prevBtn.x, prevBtn.y, prevBtn.width, prevBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(smallButtonFont)
    love.graphics.printf("<", prevBtn.x, prevBtn.y + 8, prevBtn.width, "center")

    -- Next font button
    local nextBtn = self.fontSection.nextButton
    love.graphics.setColor(nextBtn.hovered and 0.7 or 0.5, nextBtn.hovered and 0.7 or 0.5, nextBtn.hovered and 0.9 or 0.7,
        1)
    roundRect("fill", nextBtn.x, nextBtn.y, nextBtn.width, nextBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", nextBtn.x, nextBtn.y, nextBtn.width, nextBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(">", nextBtn.x, nextBtn.y + 8, nextBtn.width, "center")

    -- Sound Effect Volume setting
    love.graphics.setFont(labelFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Sound Effect Volume: " .. tostring(SETTINGS.soundEffectVolume or 0), 0,
        self.soundSection.y + 15,
        love.graphics.getWidth(), "center")

    local soundMinusBtn = self.soundSection.minusButton
    love.graphics.setColor(soundMinusBtn.hovered and 0.7 or 0.5, soundMinusBtn.hovered and 0.7 or 0.5,
        soundMinusBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", soundMinusBtn.x, soundMinusBtn.y, soundMinusBtn.width, soundMinusBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", soundMinusBtn.x, soundMinusBtn.y, soundMinusBtn.width, soundMinusBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(smallButtonFont)
    love.graphics.printf("-", soundMinusBtn.x, soundMinusBtn.y + 8, soundMinusBtn.width, "center")

    local soundPlusBtn = self.soundSection.plusButton
    love.graphics.setColor(soundPlusBtn.hovered and 0.7 or 0.5, soundPlusBtn.hovered and 0.7 or 0.5,
        soundPlusBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", soundPlusBtn.x, soundPlusBtn.y, soundPlusBtn.width, soundPlusBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", soundPlusBtn.x, soundPlusBtn.y, soundPlusBtn.width, soundPlusBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("+", soundPlusBtn.x, soundPlusBtn.y + 8, soundPlusBtn.width, "center")

    -- Confetti Amount setting
    love.graphics.setFont(labelFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Confetti Amount: " .. tostring(SETTINGS.confettiAmount or 0), 0, self.confettiSection.y + 15,
        love.graphics.getWidth(), "center")

    local confettiMinusBtn = self.confettiSection.minusButton
    love.graphics.setColor(confettiMinusBtn.hovered and 0.7 or 0.5, confettiMinusBtn.hovered and 0.7 or 0.5,
        confettiMinusBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", confettiMinusBtn.x, confettiMinusBtn.y, confettiMinusBtn.width, confettiMinusBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", confettiMinusBtn.x, confettiMinusBtn.y, confettiMinusBtn.width, confettiMinusBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(smallButtonFont)
    love.graphics.printf("-", confettiMinusBtn.x, confettiMinusBtn.y + 8, confettiMinusBtn.width, "center")

    local confettiPlusBtn = self.confettiSection.plusButton
    love.graphics.setColor(confettiPlusBtn.hovered and 0.7 or 0.5, confettiPlusBtn.hovered and 0.7 or 0.5,
        confettiPlusBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", confettiPlusBtn.x, confettiPlusBtn.y, confettiPlusBtn.width, confettiPlusBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", confettiPlusBtn.x, confettiPlusBtn.y, confettiPlusBtn.width, confettiPlusBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("+", confettiPlusBtn.x, confettiPlusBtn.y + 8, confettiPlusBtn.width, "center")

    -- Reset data button
    love.graphics.setColor(self.resetButton.hovered and 0.9 or 0.7, self.resetButton.hovered and 0.4 or 0.2,
        self.resetButton.hovered and 0.4 or 0.2, 1)
    roundRect("fill", self.resetButton.x, self.resetButton.y, self.resetButton.width, self.resetButton.height, 12, 12)
    love.graphics.setColor(0.5, 0.1, 0.1, 1)
    roundRect("line", self.resetButton.x, self.resetButton.y, self.resetButton.width, self.resetButton.height, 12, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("Reset All Data", self.resetButton.x,
        self.resetButton.y + self.resetButton.height / 2 - buttonFont:getHeight() / 2, self.resetButton.width, "center")

    -- Back button
    love.graphics.setColor(self.backButton.hovered and 0.7 or 0.5, self.backButton.hovered and 0.7 or 0.5,
        self.backButton.hovered and 0.9 or 0.7, 1)
    roundRect("fill", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 12, 12)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", self.backButton.x, self.backButton.y, self.backButton.width, self.backButton.height, 12, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Back to Main Menu", self.backButton.x,
        self.backButton.y + self.backButton.height / 2 - buttonFont:getHeight() / 2, self.backButton.width, "center")
end

function SettingsScene:drawResetWarning(labelFont, buttonFont)
    local dialog = self.warningDialog

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Warning dialog background
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    roundRect("fill", dialog.x, dialog.y, dialog.width, dialog.height, 12, 12)
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    roundRect("line", dialog.x, dialog.y, dialog.width, dialog.height, 12, 12)

    -- Warning text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(labelFont)
    love.graphics.printf("WARNING!", dialog.x, dialog.y + 20, dialog.width, "center")

    local warningFont = love.graphics.newFont(SETTINGS.font, 18)
    love.graphics.setFont(warningFont)
    love.graphics.printf(
        "This will delete all your settings,\nAPI token, and kanji data.\n\nYou will be returned to the\nwelcome screen to start over.\n\nAre you sure?",
        dialog.x + 20, dialog.y + 60, dialog.width - 40, "center")

    -- Confirm button
    local confirmBtn = dialog.confirmButton
    love.graphics.setColor(confirmBtn.hovered and 0.9 or 0.7, confirmBtn.hovered and 0.4 or 0.2,
        confirmBtn.hovered and 0.4 or 0.2, 1)
    roundRect("fill", confirmBtn.x, confirmBtn.y, confirmBtn.width, confirmBtn.height, 8, 8)
    love.graphics.setColor(0.5, 0.1, 0.1, 1)
    roundRect("line", confirmBtn.x, confirmBtn.y, confirmBtn.width, confirmBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("Yes", confirmBtn.x, confirmBtn.y + confirmBtn.height / 2 - buttonFont:getHeight() / 2,
        confirmBtn.width, "center")

    -- Cancel button
    local cancelBtn = dialog.cancelButton
    love.graphics.setColor(cancelBtn.hovered and 0.7 or 0.5, cancelBtn.hovered and 0.7 or 0.5,
        cancelBtn.hovered and 0.9 or 0.7, 1)
    roundRect("fill", cancelBtn.x, cancelBtn.y, cancelBtn.width, cancelBtn.height, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
    roundRect("line", cancelBtn.x, cancelBtn.y, cancelBtn.width, cancelBtn.height, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("No", cancelBtn.x, cancelBtn.y + cancelBtn.height / 2 - buttonFont:getHeight() / 2,
        cancelBtn.width, "center")
end

-- Return the scene object so it can be registered by the SceneManager
return SettingsScene
