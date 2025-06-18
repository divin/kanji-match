local getKanjiData, _ = require("utils.kanjiData")
SCENE_MANAGER = require("objects.sceneManager")

FONTS = {
    gothic = "assets/fonts/msgothic.ttc",
    keifont = "assets/fonts/keifont.ttf",
    sanafon = "assets/fonts/snsanafonmaru.ttf",
}

SETTINGS = {
    userLevel = 22,
    font = FONTS.keifont,
    groupsPerLesson = 5
}

SOUND_SOURCES = {
    click = love.audio.newSource("assets/sounds/first-click.wav", "static"),
    unclick = love.audio.newSource("assets/sounds/second-click.wav", "static"),
    correct = love.audio.newSource("assets/sounds/correct.wav", "static"),
    incorrect = love.audio.newSource("assets/sounds/incorrect.wav", "static"),
}

function love.load()
    -- Initialize LÖVE settings
    love.window.setTitle("Kanji Match")
    love.window.setMode(800, 600, { resizable = false, vsync = true })
    local r, g, b = love.math.colorFromBytes(98, 109, 115)
    love.graphics.setBackgroundColor(r, g, b)

    -- Load a scence, register it, and switch to it
    local scene = require("scenes.game")
    SCENE_MANAGER:register("InitialScene", scene)
    SCENE_MANAGER:switchTo("InitialScene")
end

function love.update(dt)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.update then
        SCENE_MANAGER.currentScene:update(dt)
    end
end

function love.draw()
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.draw then
        SCENE_MANAGER.currentScene:draw()
    end
end

function love.keypressed(key, scancode, isrepeat)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.keypressed then
        SCENE_MANAGER.currentScene:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.keypressed then
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
