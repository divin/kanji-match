local Card = require("objects.card")
local shuffleTable = require("utils.shuffleTable")

local CardLayoutManager = {}
CardLayoutManager.__index = CardLayoutManager

-- Constructor
function CardLayoutManager:new(maxCols, maxRows, cardWidth, cardHeight, spacing, topMargin)
    assert(type(maxCols) == "number" and maxCols > 0, "maxCols must be a positive number")
    assert(type(maxRows) == "number" and maxRows > 0, "maxRows must be a positive number")
    assert(type(cardWidth) == "number" and cardWidth > 0, "cardWidth must be a positive number")
    assert(type(cardHeight) == "number" and cardHeight > 0, "cardHeight must be a positive number")

    local instance = setmetatable({}, CardLayoutManager)

    instance.maxCols = maxCols
    instance.maxRows = maxRows
    instance.cardWidth = cardWidth
    instance.cardHeight = cardHeight
    instance.spacing = spacing or 16
    instance.topMargin = topMargin or 32

    -- Calculate derived values
    instance.totalWidth = instance.maxCols * instance.cardWidth + (instance.maxCols - 1) * instance.spacing
    instance.totalHeight = instance.maxRows * instance.cardHeight + (instance.maxRows - 1) * instance.spacing

    -- Calculate max cards per set (must be even for pairs)
    instance.maxCardsPerSet = instance.maxRows * instance.maxCols
    if instance.maxCardsPerSet % 2 ~= 0 then
        instance.maxCardsPerSet = instance.maxCardsPerSet - 1
    end

    return instance
end

-- Create card sets from kanji group data
function CardLayoutManager:createCardSets(kanjiGroup, kanjiFont, meaningFont, onCardClickCallback)
    assert(type(kanjiGroup) == "table", "kanjiGroup must be a table")
    assert(type(onCardClickCallback) == "function", "onCardClickCallback must be a function")

    -- Total cards needed (each kanji has character + meaning = 2 cards)
    local totalCards = #kanjiGroup * 2

    -- Calculate number of sets needed
    local numberOfSets = math.ceil(totalCards / self.maxCardsPerSet)
    local cardsPerSet = math.ceil(totalCards / numberOfSets)

    -- Make cardsPerSet even
    if cardsPerSet % 2 ~= 0 then
        cardsPerSet = cardsPerSet + 1
    end

    -- Create all card data first
    local allCardData = {}
    for _, kanji in ipairs(kanjiGroup) do
        local id = kanji.character
        table.insert(allCardData, { text = kanji.character, pairId = id, type = "character" })
        table.insert(allCardData, { text = kanji.meaning, pairId = id, type = "meaning" })
    end

    -- Create card sets
    local cardSets = {}
    for setIndex = 1, numberOfSets do
        local setCardData = {}

        -- Get cards for this set
        local startIdx = (setIndex - 1) * cardsPerSet + 1
        local endIdx = math.min(startIdx + cardsPerSet - 1, #allCardData)

        for i = startIdx, endIdx do
            table.insert(setCardData, allCardData[i])
        end

        -- Shuffle the card data for this set
        setCardData = shuffleTable(setCardData)

        -- Create positioned card objects
        local cards = self:_createPositionedCards(setCardData, kanjiFont, meaningFont, onCardClickCallback)

        table.insert(cardSets, cards)
    end

    return cardSets
end

-- Get card position based on index
function CardLayoutManager:getCardPosition(index)
    assert(type(index) == "number" and index > 0, "index must be a positive number")

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local startX = (screenWidth - self.totalWidth) / 2
    local startY = ((screenHeight - self.totalHeight) / 2) + self.topMargin

    local row = math.ceil(index / self.maxCols)
    local col = ((index - 1) % self.maxCols) + 1

    local x = startX + (col - 1) * (self.cardWidth + self.spacing)
    local y = startY + (row - 1) * (self.cardHeight + self.spacing)

    return x, y
end

-- Get layout information
function CardLayoutManager:getLayoutInfo()
    return {
        maxCols = self.maxCols,
        maxRows = self.maxRows,
        cardWidth = self.cardWidth,
        cardHeight = self.cardHeight,
        spacing = self.spacing,
        topMargin = self.topMargin,
        totalWidth = self.totalWidth,
        totalHeight = self.totalHeight,
        maxCardsPerSet = self.maxCardsPerSet
    }
end

-- Update layout parameters
function CardLayoutManager:updateLayout(maxCols, maxRows, cardWidth, cardHeight, spacing, topMargin)
    if maxCols then self.maxCols = maxCols end
    if maxRows then self.maxRows = maxRows end
    if cardWidth then self.cardWidth = cardWidth end
    if cardHeight then self.cardHeight = cardHeight end
    if spacing then self.spacing = spacing end
    if topMargin then self.topMargin = topMargin end

    -- Recalculate derived values
    self.totalWidth = self.maxCols * self.cardWidth + (self.maxCols - 1) * self.spacing
    self.totalHeight = self.maxRows * self.cardHeight + (self.maxRows - 1) * self.spacing

    self.maxCardsPerSet = self.maxRows * self.maxCols
    if self.maxCardsPerSet % 2 ~= 0 then
        self.maxCardsPerSet = self.maxCardsPerSet - 1
    end
end

-- Private method to create positioned card objects
function CardLayoutManager:_createPositionedCards(setCardData, kanjiFont, meaningFont, onCardClickCallback)
    local cards = {}

    for i = 1, #setCardData do
        local x, y = self:getCardPosition(i)
        local cardData = setCardData[i]
        local font = cardData.type == "character" and kanjiFont or meaningFont

        local card = Card:new(
            x,                  -- x position
            y,                  -- y position
            cardData.text,      -- text (character or meaning)
            self.cardWidth,     -- width
            self.cardHeight,    -- height
            font,               -- font
            onCardClickCallback -- onClick callback
        )

        card.pairId = cardData.pairId
        card.type = cardData.type
        table.insert(cards, card)
    end

    return cards
end

return CardLayoutManager
