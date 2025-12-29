local Blitbuffer = require("ffi/blitbuffer")
local ButtonTable = require("ui/widget/buttontable")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Screen = Device.screen
local _ = require("gettext")

local Game = require("game")

local SolitaireUI = InputContainer:extend{
    name = "solitaire_ui",
    modal = true,
    covers_fullscreen = true,
}

function SolitaireUI:init()
    self.dimen = Screen:getSize()
    self.screen_width = self.dimen.w
    self.screen_height = self.dimen.h
    
    -- UI element heights
    self.status_bar_height = 35
    self.button_bar_height = 50
    
    -- Card dimensions
    self.card_width = math.floor(self.screen_width / 9)
    self.card_height = math.floor(self.card_width * 1.4)
    self.card_spacing = math.floor(self.card_width * 0.15)
    self.stack_offset = math.floor(self.card_height * 0.35)
    
    -- Layout positions
    self.margin = math.floor(self.screen_width * 0.02)
    
    -- Fonts
    self.rank_font = Font:getFace("cfont", math.floor(self.card_width * 0.22))
    self.suit_center_font = Font:getFace("cfont", math.floor(self.card_width * 0.30))
    self.small_font = Font:getFace("cfont", math.floor(self.card_width * 0.22))
    self.status_font = Font:getFace("cfont", 16)
    
    -- Game state
    self.game = Game:new()
    self.game:deal()
    
    -- Selection state
    self.selected_source = nil
    self.hint_highlight = nil
    
    -- Touch zones
    self.touch_zones = {}
    
    -- Input handling
    if Device:isTouchDevice() then
        self.ges_events = {
            Tap = {
                GestureRange:new{
                    ges = "tap",
                    range = self.dimen,
                }
            },
            Hold = {
                GestureRange:new{
                    ges = "hold",
                    range = self.dimen,
                }
            },
        }
    end
    
    if Device:hasKeys() then
        self.key_events.Close = { { "Back" }, doc = "close game" }
    end
    
    self:buildUI()
end

function SolitaireUI:buildUI()
    self.touch_zones = {}
    
    -- Calculate available height for game area
    local game_area_height = self.screen_height - self.status_bar_height - self.button_bar_height
    
    local button_bar = ButtonTable:new{
        width = self.screen_width,
        buttons = {
            {
                {
                    text = _("New Game"),
                    callback = function() self:newGame() end,
                },
                {
                    text = _("Hint"),
                    callback = function() self:showHint() end,
                },
                {
                    text = _("Auto"),
                    callback = function() self:autoMove() end,
                },
                {
                    text = _("Close"),
                    callback = function() self:onClose() end,
                },
            },
        },
        show_parent = self,
    }
    
    -- Get actual button bar height after creation
    self.button_bar_height = button_bar:getSize().h
    game_area_height = self.screen_height - self.status_bar_height - self.button_bar_height
    
    local status_text = string.format("Moves: %d  |  Score: %d", 
        self.game.moves, self.game.score)
    
    local status_bar = FrameContainer:new{
        width = self.screen_width,
        height = self.status_bar_height,
        bordersize = 0,
        padding = 5,
        background = Blitbuffer.COLOR_LIGHT_GRAY,
        CenterContainer:new{
            dimen = Geom:new{w = self.screen_width - 10, h = self.status_bar_height - 10},
            TextWidget:new{
                text = status_text,
                face = self.status_font,
            }
        }
    }
    
    -- Game area widget
    local game_area = WidgetContainer:new{
        dimen = Geom:new{
            w = self.screen_width,
            h = game_area_height,
        },
    }
    game_area._parent = self
    game_area.paintTo = function(widget, bb, x, y)
        widget._parent:drawGame(bb, x, y)
    end
    
    self[1] = FrameContainer:new{
        width = self.screen_width,
        height = self.screen_height,
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = 0,
        VerticalGroup:new{
            align = "left",
            status_bar,
            game_area,
            button_bar,
        }
    }
end

function SolitaireUI:drawGame(bb, offset_x, offset_y)
    local y_offset = offset_y + 10
    
    -- Draw top row: Stock, Waste, gap, 4 Foundations
    self:drawStock(bb, self.margin, y_offset)
    self:drawWaste(bb, self.margin + self.card_width + self.card_spacing, y_offset)
    
    -- Foundations
    local foundation_start_x = self.screen_width - (4 * self.card_width) - (3 * self.card_spacing) - self.margin
    for f = 1, 4 do
        local x = foundation_start_x + (f - 1) * (self.card_width + self.card_spacing)
        self:drawFoundation(bb, x, y_offset, f)
    end
    
    -- Draw tableau
    local tableau_y = y_offset + self.card_height + self.margin
    local total_tableau_width = 7 * self.card_width + 6 * self.card_spacing
    local tableau_start_x = (self.screen_width - total_tableau_width) / 2
    
    for col = 1, 7 do
        local x = tableau_start_x + (col - 1) * (self.card_width + self.card_spacing)
        self:drawTableauColumn(bb, x, tableau_y, col)
    end
end

function SolitaireUI:drawCard(bb, x, y, card, highlighted, is_top_card)
    local border_width = highlighted and 3 or 1
    
    -- Card background
    bb:paintRect(x, y, self.card_width, self.card_height, Blitbuffer.COLOR_WHITE)
    
    -- Card border
    bb:paintBorder(x, y, self.card_width, self.card_height, border_width, Blitbuffer.COLOR_BLACK)
    
    if card and card.face_up then
        local rank = self.game.RANKS[card.rank]
        local suit = self.game.SUITS[card.suit].symbol
        local color = self.game:getCardColor(card)
        
        local text_color = Blitbuffer.COLOR_BLACK
        if color == "red" then
            text_color = Blitbuffer.COLOR_DARK_GRAY
        end
        
        local padding = 3
        
        -- Draw rank in top-left
        local rank_widget = TextWidget:new{
            text = rank,
            face = self.rank_font,
            fgcolor = text_color,
        }
        rank_widget:paintTo(bb, x + padding, y + padding)
        rank_widget:free()
        
        -- If this is the top card (fully visible), draw center suit
        if is_top_card then
            local suit_center_widget = TextWidget:new{
                text = suit,
                face = self.suit_center_font,
                fgcolor = text_color,
            }
            local sw = suit_center_widget:getSize().w
            local sh = suit_center_widget:getSize().h
            
            -- Position in lower center of card to avoid rank overlap
            local center_x = x + (self.card_width - sw) / 2
            local center_y = y + self.card_height - sh - (self.card_height * 0.05)
            
            suit_center_widget:paintTo(bb, center_x, center_y)
            suit_center_widget:free()
        end
        
    elseif card then
        -- Face down pattern
        local pattern_margin = 4
        for py = y + pattern_margin, y + self.card_height - pattern_margin - 2, 4 do
            for px = x + pattern_margin, x + self.card_width - pattern_margin - 2, 4 do
                bb:paintRect(px, py, 2, 2, Blitbuffer.COLOR_DARK_GRAY)
            end
        end
    end
end

function SolitaireUI:drawEmptySlot(bb, x, y, label)
    bb:paintRect(x, y, self.card_width, self.card_height, Blitbuffer.COLOR_LIGHT_GRAY)
    bb:paintBorder(x, y, self.card_width, self.card_height, 1, Blitbuffer.COLOR_GRAY)
    
    if label then
        local text_widget = TextWidget:new{
            text = label,
            face = self.small_font,
            fgcolor = Blitbuffer.COLOR_DARK_GRAY,
        }
        local tw = text_widget:getSize().w
        local th = text_widget:getSize().h
        text_widget:paintTo(bb, 
            x + (self.card_width - tw) / 2, 
            y + (self.card_height - th) / 2)
        text_widget:free()
    end
end

function SolitaireUI:drawStock(bb, x, y)
    table.insert(self.touch_zones, {
        x = x, y = y, w = self.card_width, h = self.card_height,
        type = "stock"
    })
    
    if #self.game.stock > 0 then
        local card = {face_up = false}
        self:drawCard(bb, x, y, card, false, true)
        
        local count_text = tostring(#self.game.stock)
        local text_widget = TextWidget:new{
            text = count_text,
            face = self.small_font,
            fgcolor = Blitbuffer.COLOR_BLACK,
        }
        local tw = text_widget:getSize().w
        text_widget:paintTo(bb, x + (self.card_width - tw) / 2, y + self.card_height + 2)
        text_widget:free()
    else
        self:drawEmptySlot(bb, x, y, "↺")
    end
end

function SolitaireUI:drawWaste(bb, x, y)
    table.insert(self.touch_zones, {
        x = x, y = y, w = self.card_width, h = self.card_height,
        type = "waste"
    })
    
    local is_selected = self.selected_source and 
        self.selected_source.type == "waste"
    local is_hint = self.hint_highlight and 
        (self.hint_highlight.type == "waste_to_foundation" or 
         self.hint_highlight.type == "waste_to_tableau")
    
    if #self.game.waste > 0 then
        local card = self.game.waste[#self.game.waste]
        self:drawCard(bb, x, y, card, is_selected or is_hint, true)
    else
        self:drawEmptySlot(bb, x, y, nil)
    end
end

function SolitaireUI:drawFoundation(bb, x, y, foundation_idx)
    table.insert(self.touch_zones, {
        x = x, y = y, w = self.card_width, h = self.card_height,
        type = "foundation", index = foundation_idx
    })
    
    local foundation = self.game.foundations[foundation_idx]
    local is_hint = self.hint_highlight and 
        self.hint_highlight.foundation == foundation_idx
    
    if #foundation > 0 then
        local card = foundation[#foundation]
        self:drawCard(bb, x, y, card, is_hint, true)
    else
        local suit_symbol = Game.SUITS[foundation_idx].symbol
        self:drawEmptySlot(bb, x, y, suit_symbol)
    end
end

function SolitaireUI:drawTableauColumn(bb, x, y, col_idx)
    local column = self.game.tableau[col_idx]
    
    local is_selected_col = self.selected_source and 
        self.selected_source.type == "tableau" and 
        self.selected_source.index == col_idx
    
    local is_hint_from = self.hint_highlight and 
        self.hint_highlight.from == col_idx
    local is_hint_to = self.hint_highlight and 
        (self.hint_highlight.to == col_idx or self.hint_highlight.tableau == col_idx)
    
    if #column == 0 then
        table.insert(self.touch_zones, {
            x = x, y = y, w = self.card_width, h = self.card_height,
            type = "tableau", index = col_idx, card_pos = 1
        })
        local highlight = is_hint_to
        if highlight then
            bb:paintRect(x, y, self.card_width, self.card_height, Blitbuffer.COLOR_GRAY)
        end
        self:drawEmptySlot(bb, x, y, "K")
    else
        for i, card in ipairs(column) do
            local card_y = y + (i - 1) * self.stack_offset
            local card_height = (i == #column) and self.card_height or self.stack_offset
            
            local is_card_selected = is_selected_col and 
                i >= self.selected_source.card_pos
            local is_card_hint = (is_hint_from and self.hint_highlight.card_idx and 
                i >= self.hint_highlight.card_idx) or (is_hint_to and i == #column)
            
            table.insert(self.touch_zones, {
                x = x, y = card_y, w = self.card_width, h = card_height,
                type = "tableau", index = col_idx, card_pos = i
            })
            
            local is_top = (i == #column)
            self:drawCard(bb, x, card_y, card, is_card_selected or is_card_hint, is_top)
        end
    end
end

function SolitaireUI:findTouchZone(x, y)
    for i = #self.touch_zones, 1, -1 do
        local zone = self.touch_zones[i]
        if x >= zone.x and x <= zone.x + zone.w and
           y >= zone.y and y <= zone.y + zone.h then
            return zone
        end
    end
    return nil
end

function SolitaireUI:onTap(arg, ges)
    local pos = ges.pos
    local zone = self:findTouchZone(pos.x, pos.y)
    
    if not zone then
        self.selected_source = nil
        self:refreshUI()
        return true
    end
    
    self.hint_highlight = nil
    
    if zone.type == "stock" then
        self.selected_source = nil
        self.game:drawFromStock()
        self:refreshUI()
        return true
    end
    
    if zone.type == "waste" then
        if self.selected_source then
            self.selected_source = nil
        else
            if #self.game.waste > 0 then
                self.selected_source = {type = "waste"}
            end
        end
        self:refreshUI()
        return true
    end
    
    if zone.type == "foundation" then
        if self.selected_source then
            local success = false
            if self.selected_source.type == "waste" then
                success = self.game:moveToFoundation("waste", nil, zone.index)
            elseif self.selected_source.type == "tableau" then
                local col = self.game.tableau[self.selected_source.index]
                if self.selected_source.card_pos == #col then
                    success = self.game:moveToFoundation("tableau", 
                        self.selected_source.index, zone.index)
                end
            end
            self.selected_source = nil
            if success and self.game:checkWin() then
                self:showWinMessage()
            end
        end
        self:refreshUI()
        return true
    end
    
    if zone.type == "tableau" then
        if self.selected_source then
            local success = false
            if self.selected_source.type == "waste" then
                success = self.game:moveToTableau("waste", nil, nil, zone.index)
            elseif self.selected_source.type == "tableau" then
                if self.selected_source.index ~= zone.index then
                    success = self.game:moveToTableau("tableau", 
                        self.selected_source.index, 
                        self.selected_source.card_pos, 
                        zone.index)
                end
            elseif self.selected_source.type == "foundation" then
                success = self.game:moveToTableau("foundation",
                    self.selected_source.index, nil, zone.index)
            end
            self.selected_source = nil
            if success and self.game:checkWin() then
                self:showWinMessage()
            end
        else
            local col = self.game.tableau[zone.index]
            if #col > 0 then
                local card_pos = zone.card_pos
                if col[card_pos] and col[card_pos].face_up then
                    self.selected_source = {
                        type = "tableau",
                        index = zone.index,
                        card_pos = card_pos
                    }
                end
            end
        end
        self:refreshUI()
        return true
    end
    
    return true
end

function SolitaireUI:onHold(arg, ges)
    local pos = ges.pos
    local zone = self:findTouchZone(pos.x, pos.y)
    
    if zone then
        if zone.type == "waste" and #self.game.waste > 0 then
            local card = self.game.waste[#self.game.waste]
            for f = 1, 4 do
                if self.game:canPlaceOnFoundation(card, f) then
                    self.game:moveToFoundation("waste", nil, f)
                    if self.game:checkWin() then
                        self:showWinMessage()
                    end
                    break
                end
            end
        elseif zone.type == "tableau" then
            local col = self.game.tableau[zone.index]
            if #col > 0 then
                local card = col[#col]
                if card.face_up then
                    for f = 1, 4 do
                        if self.game:canPlaceOnFoundation(card, f) then
                            self.game:moveToFoundation("tableau", zone.index, f)
                            if self.game:checkWin() then
                                self:showWinMessage()
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    
    self.selected_source = nil
    self:refreshUI()
    return true
end

function SolitaireUI:refreshUI()
    self.touch_zones = {}
    self:buildUI()
    UIManager:setDirty(self, "partial")
end

function SolitaireUI:newGame()
    self.game:deal()
    self.selected_source = nil
    self.hint_highlight = nil
    self:refreshUI()
end

function SolitaireUI:showHint()
    local hint = self.game:getHint()
    if hint then
        self.hint_highlight = hint
        self:refreshUI()
        
        UIManager:scheduleIn(2, function()
            self.hint_highlight = nil
            if self[1] then
                self:refreshUI()
            end
        end)
    else
        UIManager:show(InfoMessage:new{
            text = _("No moves available. Try drawing from stock."),
            timeout = 2,
        })
    end
end

function SolitaireUI:autoMove()
    local moved = true
    local total_moves = 0
    
    while moved and total_moves < 52 do
        moved = self.game:autoMoveToFoundation()
        if moved then
            total_moves = total_moves + 1
        end
    end
    
    self:refreshUI()
    
    if self.game:checkWin() then
        self:showWinMessage()
    elseif total_moves == 0 then
        UIManager:show(InfoMessage:new{
            text = _("No cards can be automatically moved to foundations."),
            timeout = 2,
        })
    end
end

function SolitaireUI:showWinMessage()
    UIManager:show(InfoMessage:new{
        text = string.format(
            _("Congratulations! You won!\n\nMoves: %d\nScore: %d"),
            self.game.moves, self.game.score
        ),
    })
end

function SolitaireUI:onClose()
    UIManager:close(self)
    return true
end

function SolitaireUI:onCloseWidget()
    UIManager:setDirty(nil, "full")
end

return SolitaireUI