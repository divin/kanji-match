-- Load runtime loader for HTTPS support
local major, minor, _, _ = love.getVersion()
if major < 12 then
    https = nil
    local runtimeLoader = require("runtime.loader")
    https = runtimeLoader.loadHTTPS()
end

local json = require("libs.json")
local color = require("utils.colors")
local createGradientMesh = require("utils.gradient")

local Settings = require("objects.settings")
local WaniKani = require("objects.wanikani")
SCENE_MANAGER = require("objects.sceneManager")

-- Available fonts
FONTS = {
    gothic = "assets/fonts/msgothic.ttc",
    keifont = "assets/fonts/keifont.ttf",
    sanafon = "assets/fonts/snsanafonmaru.ttf",
}

-- Default settings
SETTINGS = Settings:new(FONTS.keifont)

-- Sound sources
SOUND_SOURCES = {
    click = love.audio.newSource("assets/sounds/first-click.wav", "static"),
    unclick = love.audio.newSource("assets/sounds/second-click.wav", "static"),
    correct = love.audio.newSource("assets/sounds/correct.wav", "static"),
    incorrect = love.audio.newSource("assets/sounds/incorrect.wav", "static"),
    success = love.audio.newSource("assets/sounds/tada-fanfare.wav", "static"),
}

-- Gradient for background
GRADIENT = nil

-- Loading state for API validation
LOADING_API_VALIDATION = false

-- Available scenes
SCENES = {
    welcomeScene = "scenes.welcomeScene",
    mainMenuScene = "scenes.mainMenuScene",
    gameScene = "scenes.gameScene",
    gameOverviewScene = "scenes.gameOverviewScene",
    settingsScene = "scenes.settingsScene",
}

function love.load()
    -- Initialize LÖVE settings
    local icon = love.image.newImageData("assets/images/icon.png")
    love.window.setIcon(icon)

    local r, g, b = love.math.colorFromBytes(98, 109, 115)
    love.graphics.setBackgroundColor(r, g, b)

    -- Background gradient
    GRADIENT = createGradientMesh(
        love.graphics.getWidth(),
        love.graphics.getHeight(),
        color.rgbTable(48, 67, 82),
        color.rgbTable(139, 139, 139)
    )

    -- Load settings if available
    SETTINGS:load()

    -- Load and register scences
    for _, scenePath in pairs(SCENES) do
        local sceneModule = require(scenePath)
        assert(sceneModule, "Failed to load scene module: " .. scenePath)
        assert(type(sceneModule) == "table", "Scene module is not a table: " .. scenePath)
        SCENE_MANAGER:register(scenePath, sceneModule)
    end

    -- Switch to the initial scene based on API token
    if SETTINGS.apiToken == nil or SETTINGS.apiToken == "" then
        SCENE_MANAGER:switchTo(SCENES.welcomeScene)
    else
        -- Show loading state and validate API token with WaniKani API
        LOADING_API_VALIDATION = true
        local wanikani = WaniKani:new(SETTINGS.apiToken)
        wanikani:getUserInfo(function(success, userInfo)
            LOADING_API_VALIDATION = false
            if success and userInfo.subscription.active then
                -- Token is valid and subscription is active
                SETTINGS.isValidToken = true
                SETTINGS.userLevel = userInfo.level
                SETTINGS.activeSubscription = userInfo.subscription.active
                SETTINGS.maxGrantedLevel = userInfo.subscription.max_level_granted
                SETTINGS:save()

                -- Switch to main menu scene
                SCENE_MANAGER:switchTo(SCENES.mainMenuScene)
            else
                -- Token is invalid or subscription is not active
                SETTINGS.isValidToken = false
                SETTINGS.activeSubscription = false
                SETTINGS:save()

                -- Switch to welcome scene to re-enter token
                SCENE_MANAGER:switchTo(SCENES.welcomeScene)
            end
        end)
    end
end

function love.update(dt)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.update then
        SCENE_MANAGER.currentScene:update(dt)
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    love.graphics.draw(GRADIENT, 0, 0)

    if LOADING_API_VALIDATION then
        -- Show loading screen during API validation
        local width, height = love.graphics.getDimensions()
        local loadingFont = love.graphics.newFont(SETTINGS.font, 24)
        love.graphics.setFont(loadingFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Validating API Token...", 0, height / 2 - 12, width, "center")
    elseif SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.draw then
        SCENE_MANAGER.currentScene:draw()
    end
end

function love.textinput(t)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.textinput then
        SCENE_MANAGER.currentScene:textinput(t)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.keypressed then
        SCENE_MANAGER.currentScene:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.keyreleased then
        SCENE_MANAGER.currentScene:keyreleased(key, scancode)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.mousepressed then
        SCENE_MANAGER.currentScene:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.mousemoved then
        SCENE_MANAGER.currentScene:mousemoved(x, y, dx, dy, istouch)
    end
end
