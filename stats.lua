local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")

local Stats = {}

function Stats:new()
    local o = {
        stats_path = DataStorage:getSettingsDir() .. "/solitaire_stats.lua",
    }
    setmetatable(o, self)
    self.__index = self
    o:load()
    return o
end

function Stats:getDefaults()
    return {
        -- Overall stats
        games_played = 0,
        games_won = 0,
        games_lost = 0,
        -- Score stats
        total_score = 0,
        best_score = 0,
        -- Move stats
        total_moves = 0,
        fewest_moves = 0,
        -- Time stats
        total_time = 0,
        best_time = 0,
        -- Streak stats
        current_win_streak = 0,
        longest_win_streak = 0,
        current_lose_streak = 0,
        -- Draw mode stats
        draw1_games_played = 0,
        draw1_games_won = 0,
        draw3_games_played = 0,
        draw3_games_won = 0,
        -- Leaderboard: top 10 best games
        leaderboard = {},
        max_leaderboard = 10,
    }
end

function Stats:load()
    local ok, settings = pcall(LuaSettings.open, LuaSettings, self.stats_path)
    if ok and settings then
        local data = settings:readSetting("stats")
        if data then
            local defaults = self:getDefaults()
            for k, v in pairs(defaults) do
                self[k] = data[k] or v
            end
            if type(self.leaderboard) ~= "table" then
                self.leaderboard = {}
            end
            self.max_leaderboard = defaults.max_leaderboard
            return
        end
    end
    local defaults = self:getDefaults()
    for k, v in pairs(defaults) do
        self[k] = v
    end
end

function Stats:save()
    local data = {}
    local defaults = self:getDefaults()
    for k, _ in pairs(defaults) do
        data[k] = self[k]
    end
    local settings = LuaSettings:open(self.stats_path)
    settings:saveSetting("stats", data)
    settings:flush()
end

-- Record a game win
function Stats:recordWin(score, moves, time_seconds, draw_mode)
    self.games_played = self.games_played + 1
    self.games_won = self.games_won + 1

    self.total_score = self.total_score + score
    if score > self.best_score then
        self.best_score = score
    end

    self.total_moves = self.total_moves + moves
    if self.fewest_moves == 0 or moves < self.fewest_moves then
        self.fewest_moves = moves
    end

    self.total_time = self.total_time + time_seconds
    if self.best_time == 0 or time_seconds < self.best_time then
        self.best_time = time_seconds
    end

    self.current_win_streak = self.current_win_streak + 1
    self.current_lose_streak = 0
    if self.current_win_streak > self.longest_win_streak then
        self.longest_win_streak = self.current_win_streak
    end

    if draw_mode == 3 then
        self.draw3_games_played = self.draw3_games_played + 1
        self.draw3_games_won = self.draw3_games_won + 1
    else
        self.draw1_games_played = self.draw1_games_played + 1
        self.draw1_games_won = self.draw1_games_won + 1
    end

    self:addToLeaderboard(score, moves, time_seconds, draw_mode)
    self:save()
end

-- Record a game loss (abandoned)
function Stats:recordLoss(draw_mode)
    self.games_played = self.games_played + 1
    self.games_lost = self.games_lost + 1

    self.current_win_streak = 0
    self.current_lose_streak = self.current_lose_streak + 1

    if draw_mode == 3 then
        self.draw3_games_played = self.draw3_games_played + 1
    else
        self.draw1_games_played = self.draw1_games_played + 1
    end

    self:save()
end

-- Add entry to leaderboard (sorted by score descending)
function Stats:addToLeaderboard(score, moves, time_seconds, draw_mode)
    local entry = {
        score = score,
        moves = moves,
        time = time_seconds,
        draw_mode = draw_mode,
        date = os.date("%Y-%m-%d %H:%M"),
    }

    local inserted = false
    for i, existing in ipairs(self.leaderboard) do
        if score > existing.score then
            table.insert(self.leaderboard, i, entry)
            inserted = true
            break
        end
    end

    if not inserted then
        table.insert(self.leaderboard, entry)
    end

    while #self.leaderboard > self.max_leaderboard do
        table.remove(self.leaderboard)
    end
end

-- Get win percentage
function Stats:getWinPercentage()
    if self.games_played == 0 then return 0 end
    return math.floor((self.games_won / self.games_played) * 100)
end

-- Get average score (wins only)
function Stats:getAverageScore()
    if self.games_won == 0 then return 0 end
    return math.floor(self.total_score / self.games_won)
end

-- Get average moves (wins only)
function Stats:getAverageMoves()
    if self.games_won == 0 then return 0 end
    return math.floor(self.total_moves / self.games_won)
end

-- Get average time (wins only)
function Stats:getAverageTime()
    if self.games_won == 0 then return 0 end
    return math.floor(self.total_time / self.games_won)
end

-- Format time for display
function Stats:formatTime(seconds)
    if not seconds or seconds == 0 then return "--:--" end
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", mins, secs)
end

-- Get formatted stats text for display
function Stats:getStatsText()
    local lines = {}

    table.insert(lines, "══════ GAME STATISTICS ══════")
    table.insert(lines, "")
    table.insert(lines, string.format("Games Played:    %d", self.games_played))
    table.insert(lines, string.format("Games Won:       %d", self.games_won))
    table.insert(lines, string.format("Games Lost:      %d", self.games_lost))
    table.insert(lines, string.format("Win Rate:        %d%%", self:getWinPercentage()))
    table.insert(lines, "")
    table.insert(lines, "── Scores ──")
    table.insert(lines, string.format("Best Score:      %d", self.best_score))
    table.insert(lines, string.format("Average Score:   %d", self:getAverageScore()))
    table.insert(lines, "")
    table.insert(lines, "── Moves ──")
    table.insert(lines, string.format("Fewest Moves:    %s",
        self.fewest_moves > 0 and tostring(self.fewest_moves) or "--"))
    table.insert(lines, string.format("Average Moves:   %s",
        self.games_won > 0 and tostring(self:getAverageMoves()) or "--"))
    table.insert(lines, "")
    table.insert(lines, "── Time ──")
    table.insert(lines, string.format("Best Time:       %s", self:formatTime(self.best_time)))
    table.insert(lines, string.format("Average Time:    %s", self:formatTime(self:getAverageTime())))
    table.insert(lines, "")
    table.insert(lines, "── Streaks ──")
    table.insert(lines, string.format("Current Streak:  %d wins", self.current_win_streak))
    table.insert(lines, string.format("Longest Streak:  %d wins", self.longest_win_streak))

    if self.draw1_games_played > 0 or self.draw3_games_played > 0 then
        table.insert(lines, "")
        table.insert(lines, "── By Draw Mode ──")
        if self.draw1_games_played > 0 then
            local d1_pct = math.floor((self.draw1_games_won / self.draw1_games_played) * 100)
            table.insert(lines, string.format("Draw-1:  %d/%d (%d%%)",
                self.draw1_games_won, self.draw1_games_played, d1_pct))
        end
        if self.draw3_games_played > 0 then
            local d3_pct = math.floor((self.draw3_games_won / self.draw3_games_played) * 100)
            table.insert(lines, string.format("Draw-3:  %d/%d (%d%%)",
                self.draw3_games_won, self.draw3_games_played, d3_pct))
        end
    end

    return table.concat(lines, "\n")
end

-- Get formatted leaderboard text for display
function Stats:getLeaderboardText()
    if #self.leaderboard == 0 then
        return "No games won yet!\n\nWin a game to see your scores here."
    end

    local lines = {}
    table.insert(lines, "══════ BEST SCORES ══════")
    table.insert(lines, "")

    for i, entry in ipairs(self.leaderboard) do
        local mode_str = entry.draw_mode == 3 and "D3" or "D1"
        local time_str = self:formatTime(entry.time)
        table.insert(lines, string.format(
            "#%d  Score: %d  Moves: %d  Time: %s  %s",
            i, entry.score, entry.moves, time_str, mode_str
        ))
        table.insert(lines, string.format("     %s", entry.date))
        if i < #self.leaderboard then
            table.insert(lines, "")
        end
    end

    return table.concat(lines, "\n")
end

-- Reset all stats
function Stats:reset()
    local defaults = self:getDefaults()
    for k, v in pairs(defaults) do
        self[k] = v
    end
    self:save()
end

return Stats