local roundRect = require("libs.roundRect")

local Card = {}
Card.__index = Card

function Card:new(x, y, text, width, height, font, onClickCallback)
    local instance = setmetatable({}, Card)
    instance.x = x or 0
    instance.y = y or 0
    instance.text = text
    instance.width = width or 100
    instance.height = height or 100
    instance.onClickCallback = onClickCallback
    instance.font = font or love.graphics.getFont()
    instance.isHovered = false
    instance.isSelected = false
    return instance
end

function Card:draw()
    if self.isHovered or self.isSelected then
        love.graphics.setColor(0.8, 0.8, 1) -- Light blue tint
    else
        love.graphics.setColor(1, 1, 1)     -- White
    end

    love.graphics.setFont(self.font) -- Set font for metrics and drawing

    -- Draw the card outline
    roundRect("fill", self.x, self.y, self.width, self.height, 16, 16)

    -- Draw the text, centered and wrapped
    if self.text then                 -- Ensure text is not nil to avoid errors
        local horizontal_padding = 10 -- Padding from left/right edges for the text area

        -- Calculate the width available for text wrapping
        local text_wrap_limit = self.width - (2 * horizontal_padding)

        -- Ensure the wrap limit is not negative (e.g., if card is narrower than padding)
        if text_wrap_limit < 0 then
            text_wrap_limit = 0
        end

        -- Get the wrapped text lines to calculate the total height of the text block
        -- self.font:getWrap returns (width_used, lines_table)
        local _, wrapped_text_lines = self.font:getWrap(self.text, text_wrap_limit)
        local text_block_height = #wrapped_text_lines * self.font:getHeight()

        -- Calculate the Y position for the top of the text block to achieve vertical centering
        local text_draw_y = self.y + (self.height - text_block_height) / 2

        -- Calculate the X position for love.graphics.printf.
        -- This is the left boundary of the area where text will be rendered.
        -- 'center' alignment in printf will center each line of text within this area.
        local text_draw_x = self.x + horizontal_padding

        -- Draw the text, wrapped and centered horizontally
        love.graphics.setColor(0, 0, 0) -- Set text color to black
        love.graphics.printf(self.text, text_draw_x, text_draw_y, text_wrap_limit, 'center')
    end

    love.graphics.setColor(1, 1, 1) -- Reset color to white
end

function Card:isPointInside(px, py)
    return px >= self.x and px <= self.x + self.width and
        py >= self.y and py <= self.y + self.height
end

function Card:onClick()
    if self.onClickCallback then
        self.onClickCallback(self)
    end
end

function Card:update(dt)
    -- Check if mouse is hovering
    local mx, my = love.mouse.getPosition()
    self.isHovered = self:isPointInside(mx, my)
end

return Card
