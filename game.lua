local Game = {}

-- Card suits and their properties
Game.SUITS = {
    {name = "hearts",   symbol = "♥", color = "red"},
    {name = "diamonds", symbol = "♦", color = "red"},
    {name = "clubs",    symbol = "♣", color = "black"},
    {name = "spades",   symbol = "♠", color = "black"},
}

Game.RANKS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}

function Game:new()
    local o = {
        stock = {},           -- Draw pile
        waste = {},           -- Drawn cards
        foundations = {{}, {}, {}, {}},  -- 4 foundation piles
        tableau = {{}, {}, {}, {}, {}, {}, {}},  -- 7 tableau columns
        selected = nil,       -- Currently selected card(s)
        moves = 0,
        score = 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Game:createCard(suit_idx, rank_idx)
    return {
        suit = suit_idx,
        rank = rank_idx,
        face_up = false,
    }
end

function Game:createDeck()
    local deck = {}
    for suit = 1, 4 do
        for rank = 1, 13 do
            table.insert(deck, self:createCard(suit, rank))
        end
    end
    return deck
end

function Game:shuffle(deck)
    math.randomseed(os.time())
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

function Game:deal()
    local deck = self:shuffle(self:createDeck())
    
    -- Reset all piles
    self.stock = {}
    self.waste = {}
    self.foundations = {{}, {}, {}, {}}
    self.tableau = {{}, {}, {}, {}, {}, {}, {}}
    self.selected = nil
    self.moves = 0
    self.score = 0
    
    -- Deal to tableau
    local card_idx = 1
    for col = 1, 7 do
        for row = 1, col do
            local card = deck[card_idx]
            card.face_up = (row == col)  -- Only top card face up
            table.insert(self.tableau[col], card)
            card_idx = card_idx + 1
        end
    end
    
    -- Remaining cards go to stock
    for i = card_idx, 52 do
        deck[i].face_up = false
        table.insert(self.stock, deck[i])
    end
end

function Game:getCardColor(card)
    return self.SUITS[card.suit].color
end

function Game:getCardDisplay(card)
    if not card.face_up then
        return "▒▒▒"
    end
    return self.RANKS[card.rank] .. self.SUITS[card.suit].symbol
end

function Game:canPlaceOnTableau(card, target_pile)
    if #target_pile == 0 then
        -- Empty pile: only Kings allowed
        return card.rank == 13
    end
    
    local top_card = target_pile[#target_pile]
    if not top_card.face_up then
        return false
    end
    
    -- Must be opposite color and one rank lower
    local diff_color = self:getCardColor(card) ~= self:getCardColor(top_card)
    local one_lower = card.rank == top_card.rank - 1
    
    return diff_color and one_lower
end

function Game:canPlaceOnFoundation(card, foundation_idx)
    local foundation = self.foundations[foundation_idx]
    
    if #foundation == 0 then
        -- Empty foundation: only Aces allowed
        return card.rank == 1
    end
    
    local top_card = foundation[#foundation]
    
    -- Must be same suit and one rank higher
    local same_suit = card.suit == top_card.suit
    local one_higher = card.rank == top_card.rank + 1
    
    return same_suit and one_higher
end

function Game:drawFromStock()
    if #self.stock == 0 then
        -- Recycle waste back to stock
        if #self.waste == 0 then
            return false
        end
        while #self.waste > 0 do
            local card = table.remove(self.waste)
            card.face_up = false
            table.insert(self.stock, card)
        end
        self.score = math.max(0, self.score - 20)  -- Penalty for recycling
        return true
    end
    
    -- Draw one card (or three for draw-3 variant)
    local card = table.remove(self.stock)
    card.face_up = true
    table.insert(self.waste, card)
    return true
end

function Game:moveToFoundation(source_type, source_idx, foundation_idx)
    local source_pile
    local card
    
    if source_type == "waste" then
        if #self.waste == 0 then return false end
        card = self.waste[#self.waste]
        source_pile = self.waste
    elseif source_type == "tableau" then
        if #self.tableau[source_idx] == 0 then return false end
        card = self.tableau[source_idx][#self.tableau[source_idx]]
        if not card.face_up then return false end
        source_pile = self.tableau[source_idx]
    else
        return false
    end
    
    if not self:canPlaceOnFoundation(card, foundation_idx) then
        return false
    end
    
    -- Move the card
    table.remove(source_pile)
    table.insert(self.foundations[foundation_idx], card)
    
    -- Flip newly exposed card
    if source_type == "tableau" and #source_pile > 0 then
        local new_top = source_pile[#source_pile]
        if not new_top.face_up then
            new_top.face_up = true
            self.score = self.score + 5
        end
    end
    
    self.moves = self.moves + 1
    self.score = self.score + 10
    return true
end

function Game:moveToTableau(source_type, source_idx, card_pos, target_col)
    local cards_to_move = {}
    local source_pile
    
    if source_type == "waste" then
        if #self.waste == 0 then return false end
        cards_to_move = {self.waste[#self.waste]}
        source_pile = self.waste
    elseif source_type == "tableau" then
        source_pile = self.tableau[source_idx]
        if card_pos > #source_pile then return false end
        
        -- Check if the card at position is face up
        if not source_pile[card_pos].face_up then return false end
        
        -- Get all cards from position to end
        for i = card_pos, #source_pile do
            table.insert(cards_to_move, source_pile[i])
        end
    elseif source_type == "foundation" then
        local foundation = self.foundations[source_idx]
        if #foundation == 0 then return false end
        cards_to_move = {foundation[#foundation]}
        source_pile = foundation
    else
        return false
    end
    
    if #cards_to_move == 0 then return false end
    
    -- Check if move is valid
    if not self:canPlaceOnTableau(cards_to_move[1], self.tableau[target_col]) then
        return false
    end
    
    -- Remove cards from source
    if source_type == "tableau" then
        for i = 1, #cards_to_move do
            table.remove(source_pile)
        end
    else
        table.remove(source_pile)
    end
    
    -- Add cards to target
    for _, card in ipairs(cards_to_move) do
        table.insert(self.tableau[target_col], card)
    end
    
    -- Flip newly exposed card
    if source_type == "tableau" and #source_pile > 0 then
        local new_top = source_pile[#source_pile]
        if not new_top.face_up then
            new_top.face_up = true
            self.score = self.score + 5
        end
    end
    
    self.moves = self.moves + 1
    if source_type == "foundation" then
        self.score = math.max(0, self.score - 15)  -- Penalty
    else
        self.score = self.score + 5
    end
    
    return true
end

function Game:autoMoveToFoundation()
    -- Try to automatically move cards to foundation
    local moved = false
    
    -- Check waste
    if #self.waste > 0 then
        local card = self.waste[#self.waste]
        for f = 1, 4 do
            if self:canPlaceOnFoundation(card, f) then
                if self:moveToFoundation("waste", nil, f) then
                    moved = true
                    break
                end
            end
        end
    end
    
    -- Check tableau
    if not moved then
        for t = 1, 7 do
            if #self.tableau[t] > 0 then
                local card = self.tableau[t][#self.tableau[t]]
                if card.face_up then
                    for f = 1, 4 do
                        if self:canPlaceOnFoundation(card, f) then
                            if self:moveToFoundation("tableau", t, f) then
                                moved = true
                                break
                            end
                        end
                    end
                end
            end
            if moved then break end
        end
    end
    
    return moved
end

function Game:checkWin()
    for f = 1, 4 do
        if #self.foundations[f] ~= 13 then
            return false
        end
    end
    return true
end

function Game:getHint()
    -- Find a valid move to suggest
    
    -- Check waste to foundation
    if #self.waste > 0 then
        local card = self.waste[#self.waste]
        for f = 1, 4 do
            if self:canPlaceOnFoundation(card, f) then
                return {type = "waste_to_foundation", foundation = f}
            end
        end
    end
    
    -- Check tableau to foundation
    for t = 1, 7 do
        if #self.tableau[t] > 0 then
            local card = self.tableau[t][#self.tableau[t]]
            if card.face_up then
                for f = 1, 4 do
                    if self:canPlaceOnFoundation(card, f) then
                        return {type = "tableau_to_foundation", tableau = t, foundation = f}
                    end
                end
            end
        end
    end
    
    -- Check waste to tableau
    if #self.waste > 0 then
        local card = self.waste[#self.waste]
        for t = 1, 7 do
            if self:canPlaceOnTableau(card, self.tableau[t]) then
                return {type = "waste_to_tableau", tableau = t}
            end
        end
    end
    
    -- Check tableau to tableau
    for from = 1, 7 do
        for card_idx = 1, #self.tableau[from] do
            local card = self.tableau[from][card_idx]
            if card.face_up then
                for to = 1, 7 do
                    if from ~= to and self:canPlaceOnTableau(card, self.tableau[to]) then
                        -- Avoid pointless moves (King to empty)
                        if card.rank ~= 13 or #self.tableau[to] > 0 or card_idx > 1 then
                            return {type = "tableau_to_tableau", from = from, to = to, card_idx = card_idx}
                        end
                    end
                end
            end
        end
    end
    
    -- Suggest draw
    if #self.stock > 0 or #self.waste > 0 then
        return {type = "draw"}
    end
    
    return nil
end

return Game