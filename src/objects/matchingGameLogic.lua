local MatchingGameLogic = {}
MatchingGameLogic.__index = MatchingGameLogic

-- Constructor
function MatchingGameLogic:new(maxSelections)
    local instance = setmetatable({}, MatchingGameLogic)

    instance.selectedCards = {}
    instance.maxSelections = maxSelections or 2
    instance.failedItems = {} -- Track failed attempts to only count once per set

    -- Callbacks that can be set by the user
    instance.onCardSelected = nil
    instance.onCardDeselected = nil
    instance.onMatch = nil
    instance.onMismatch = nil
    instance.onSetComplete = nil

    return instance
end

-- Set callbacks for game events
function MatchingGameLogic:setCallbacks(callbacks)
    assert(type(callbacks) == "table", "callbacks must be a table")

    if callbacks.onCardSelected then
        assert(type(callbacks.onCardSelected) == "function", "onCardSelected must be a function")
        self.onCardSelected = callbacks.onCardSelected
    end

    if callbacks.onCardDeselected then
        assert(type(callbacks.onCardDeselected) == "function", "onCardDeselected must be a function")
        self.onCardDeselected = callbacks.onCardDeselected
    end

    if callbacks.onMatch then
        assert(type(callbacks.onMatch) == "function", "onMatch must be a function")
        self.onMatch = callbacks.onMatch
    end

    if callbacks.onMismatch then
        assert(type(callbacks.onMismatch) == "function", "onMismatch must be a function")
        self.onMismatch = callbacks.onMismatch
    end

    if callbacks.onSetComplete then
        assert(type(callbacks.onSetComplete) == "function", "onSetComplete must be a function")
        self.onSetComplete = callbacks.onSetComplete
    end
end

-- Handle card click
function MatchingGameLogic:handleCardClick(card, currentSet)
    assert(type(card) == "table", "card must be a table")
    assert(type(currentSet) == "table", "currentSet must be a table")

    -- Check if card is already selected - if so, deselect it
    if card.isSelected then
        card.isSelected = false
        self:_removeSelectedCard(card)

        if self.onCardDeselected then
            self.onCardDeselected(card)
        end
        return
    end

    -- Don't allow more than max selections
    if #self.selectedCards >= self.maxSelections then
        return
    end

    -- Select the card
    card.isSelected = true
    self:_addSelectedCard(card)

    if self.onCardSelected then
        self.onCardSelected(card)
    end

    -- Check if we have enough cards selected for matching
    if #self.selectedCards == self.maxSelections then
        self:_processMatch(currentSet)
    end
end

-- Check if a set is complete (empty)
function MatchingGameLogic:isSetComplete(currentSet)
    assert(type(currentSet) == "table", "currentSet must be a table")
    return #currentSet == 0
end

-- Reset failed items tracking (call when starting new set)
function MatchingGameLogic:resetFailedItems()
    self.failedItems = {}
end

-- Get current selected cards
function MatchingGameLogic:getSelectedCards()
    return self.selectedCards
end

-- Clear current selections
function MatchingGameLogic:clearSelections()
    for _, card in ipairs(self.selectedCards) do
        card.isSelected = false
    end
    self.selectedCards = {}
end

-- Private method to add selected card
function MatchingGameLogic:_addSelectedCard(card)
    table.insert(self.selectedCards, card)
end

-- Private method to remove selected card
function MatchingGameLogic:_removeSelectedCard(card)
    for i = #self.selectedCards, 1, -1 do
        if self.selectedCards[i] == card then
            table.remove(self.selectedCards, i)
            break
        end
    end
end

-- Private method to process match attempt
function MatchingGameLogic:_processMatch(currentSet)
    local a, b = unpack(self.selectedCards)

    if a.pairId == b.pairId then
        -- Match found
        self:_handleMatch(a, b, currentSet)
    else
        -- No match
        self:_handleMismatch(a, b)
    end

    -- Clear selections for next attempt
    self.selectedCards = {}
end

-- Private method to handle successful match
function MatchingGameLogic:_handleMatch(cardA, cardB, currentSet)
    -- Remove matched cards from current set
    for i = #currentSet, 1, -1 do
        local c = currentSet[i]
        if c.pairId == cardA.pairId then
            table.remove(currentSet, i)
        end
    end

    -- Call match callback
    if self.onMatch then
        self.onMatch(cardA, cardB)
    end

    -- Check if set is complete
    if self:isSetComplete(currentSet) then
        if self.onSetComplete then
            self.onSetComplete()
        end
    end
end

-- Private method to handle failed match
function MatchingGameLogic:_handleMismatch(cardA, cardB)
    -- Reset card selection states
    cardA.isSelected = false
    cardB.isSelected = false

    -- Determine if this is the first failure for this item
    local isFirstFailure = not self.failedItems[cardA.pairId]
    if isFirstFailure then
        self.failedItems[cardA.pairId] = true
    end

    -- Call mismatch callback
    if self.onMismatch then
        self.onMismatch(cardA, cardB, isFirstFailure)
    end
end

return MatchingGameLogic
