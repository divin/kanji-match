local json = require("libs.json")
local color = require("utils.colors")
local createGradientMesh = require("utils.gradient")

local Settings = require("objects.settings")
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
}

-- Gradient for background
GRADIENT = nil

-- Available scenes
SCENES = {
    welcomeScene = "scenes.welcomeScene",
    -- mainMenuScene = "scenes.mainMenuScene",
    -- gameScene = "scenes.gameScene",
    -- gameCompleteScene = "scenes.gameCompleteScene",
    -- settingsScene = "scenes.settingsScene",
}

function love.load()
    -- Initialize LÖVE settings
    love.window.setTitle("Kanji Match")
    love.window.setMode(960, 720, { resizable = false, vsync = true })
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
        -- TODO: Validate API token here and switch to the main menu scene if valid
        SCENE_MANAGER:switchTo(SCENES.mainMenuScene)
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
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.draw then
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
