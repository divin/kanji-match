local json = require("libs.json")

--- Reads and parses kanji data from the 'kanji_groups.json' file.
--- @return table kanjiData # The parsed kanji data as a Lua table.
--- @error If the file cannot be read or if the JSON data is invalid or not a table.
local function getKanjiData()
    -- Read the JSON file
    local file = love.filesystem.read("data/kanji_groups.json")
    assert(file, "Could not read kanji_groups.json")

    local data = json.decode(file)
    assert(data, "Failed to decode JSON data from kanji_groups.json")
    assert(type(data) == "table", "Expected data to be a table")

    return data
end

--- Filters kanji data to include only kanji with a level strictly less than the specified level.
--- @param level number # The level threshold. Kanji with `kanji.level < level` will be included. Must be between 1 and 60.
--- @return table levelData # A table of kanji groups, where each kanji within the groups has a level less than the specified `level`.
--- @error If `level` is not a number, not between 2 and 60, or if no kanji data is found satisfying the criteria.
local function getKanjiDataForLevel(level)
    assert(type(level) == "number", "Level must be a number")
    assert(level >= 2 and level <= 60, "Level must be between 1 and 60")

    local kanjiData = getKanjiData()
    local levelData = {}
    for _, kanjiGroup in ipairs(kanjiData) do
        local newKanjiGroup = {}
        for _, kanji in ipairs(kanjiGroup) do
            if kanji.level < level then
                table.insert(newKanjiGroup, kanji)
            end
        end

        if #newKanjiGroup > 1 then
            table.insert(levelData, newKanjiGroup)
        end
    end

    assert(#levelData > 0, "No kanji data found for level " .. level)
    return levelData
end

return getKanjiDataForLevel
