require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls_35bag'

local DeathRoll = GameMode:extend()

DeathRoll.name = "Death Roll"
DeathRoll.hash = "DeathRoll"
DeathRoll.tagline = "Don't even bother."




function DeathRoll:new()
	DeathRoll.super:new()

	switchBGM("death_roll")

	self.level = 0
	self.grade = 0
	self.garbage = 0
	self.clear = false
	self.completed = false
	self.roll_frames = 0
	self.combo = 1
	self.randomizer = History6RollsRandomizer()

    self.SGnames = {
        "S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9",
        "m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9",
        "GM"
    }

	self.lock_drop = true
	self.enable_hold = true
	self.next_queue_length = 3

	self.coolregret_message = "COOL!!"
	self.coolregret_timer = 0
end


function DeathRoll:getARE()
	if self.frames < 2399 then return 10 end
	if self.frames < 5339 then return 8 end
	if self.frames >= 5340 then return 6 end
end

function DeathRoll:getLineARE()
	if self.frames < 2399 then return 10 end
	if self.frames < 5339 then return 8 end
	if self.frames >= 5340 then return 6 end
end

function DeathRoll:getDasLimit()
	return 5
end

function DeathRoll:getLineClearDelay()
	return 6
end

function DeathRoll:getLockDelay()
	if self.frames < 2399 then return 20 end
	if self.frames < 5339 then return 15 end
	if self.frames >= 5340 then return 10 end
end

function DeathRoll:getGravity()
	return 20
end

function DeathRoll:getGarbageLimit()
	return 8
end

function DeathRoll:getNextPiece(ruleset)
	return {
		skin = self.frames >= 2250 and "bone" or "2tie",
		shape = self.randomizer:nextPiece(),
		orientation = ruleset:getDefaultOrientation(),
	}
end

function DeathRoll:hitTorikan(old_level, new_level)
	if old_level < 500 and new_level >= 500 and self.frames > frameTime(2,28) then
		self.level = 500
		return true
	end
	if old_level < 1000 and new_level >= 1000 and self.frames > frameTime(4,56) then
		self.level = 1000
		return true
	end
	return false
end

function DeathRoll:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames < 0 then
			if self.roll_frames + 1 == 0 then
				switchBGM("credit_roll", "gm3")
				return true
			end
			return false
		elseif self.roll_frames > 3238 then
			switchBGM(nil)
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function DeathRoll:onPieceEnter()
	if (self.level % 100 ~= 99) and not self.clear and self.frames ~= 0 then
		self.level = self.level + 1
	end
end

local cleared_row_levels = {1, 2, 4, 6}
local cleared_row_points = {0.02, 0.05, 0.15, 0.6}

function DeathRoll:onLineClear(cleared_row_count)
	if not self.clear then
		local new_level = self.level + cleared_row_levels[cleared_row_count]
		self:updateSectionTimes(self.level, new_level)
		if new_level >= 1300 or self:hitTorikan(self.level, new_level) then
			if new_level >= 1300 then
				self.level = 1300
			end
			self.clear = true
			self.grid:clear()
			self.big_mode = true
			self.roll_frames = -150
		else
			self.level = math.min(new_level, 1300)
		end
		self:advanceBottomRow(-cleared_row_count)
	end
end

function DeathRoll:onPieceLock(piece, cleared_row_count)
	if cleared_row_count == 0 then self:advanceBottomRow(1) end
end

function DeathRoll:updateScore(level, drop_bonus, cleared_lines)
	if cleared_lines > 0 then
		self.score = self.score + (
			(math.ceil((level + cleared_lines) / 4) + drop_bonus) *
			cleared_lines * (cleared_lines * 2 - 1) * (self.combo * 2 - 1)
		)
		self.lines = self.lines + cleared_lines
		self.combo = self.combo + cleared_lines - 1
	else
		self.drop_bonus = 0
		self.combo = 1
	end
end

function DeathRoll:updateSectionTimes(old_level, new_level)
	if math.floor(old_level / 100) < math.floor(new_level / 100) then
		local section = math.floor(old_level / 100) + 1
		section_time = self.frames - self.section_start_time
		table.insert(self.section_times, section_time)
		self.section_start_time = self.frames
		if section_time <= frameTime(1,00) then
			self.grade = self.grade + 1
		else
			self.coolregret_message = "REGRET!!"
			self.coolregret_timer = 300
		end
	end
end

function DeathRoll:advanceBottomRow(dx)
	if self.level >= 500 and self.level < 1000 then
		self.garbage = math.max(self.garbage + dx, 0)
		if self.garbage >= self:getGarbageLimit() then
			self.grid:copyBottomRow()
			self.garbage = 0
		end
	end
end

function DeathRoll:drawGrid()
	self.grid:draw()
end

local function getLetterGrade(grade)
	if grade == 0 then
		return "1"
	else
		return "S" .. tostring(grade)
	end
end

function DeathRoll:drawScoringInfo()
	DeathRoll.super.drawScoringInfo(self)

	love.graphics.setColor(1, 1, 1, 1)

	local text_x = config["side_next"] and 320 or 240

	love.graphics.setFont(font_3x5_2)
	love.graphics.printf("GRADE", text_x, 120, 40, "left")
	love.graphics.printf("SCORE", text_x, 200, 40, "left")
	love.graphics.printf("LEVEL", text_x, 320, 40, "left")
    local sg = self.grid:checkSecretGrade()
    if sg >= 5 then
        love.graphics.printf("SECRET GRADE", 240, 430, 180, "left")
    end

	if(self.coolregret_timer > 0) then
		love.graphics.printf(self.coolregret_message, 64, 400, 160, "center")
		self.coolregret_timer = self.coolregret_timer - 1
	end

	local current_section = math.floor(self.level / 100) + 1
	-- self:drawSectionTimesWithSplits(current_section)

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(getLetterGrade(math.floor(self.grade)), text_x, 140, 90, "left")
	love.graphics.printf(self.score, text_x, 220, 90, "left")
	love.graphics.printf(self.level, text_x, 340, 50, "right")
	if self.clear then
		love.graphics.printf(self.level, text_x, 370, 50, "right")
	else
		love.graphics.printf(math.floor(self.level / 100 + 1) * 100, text_x, 370, 50, "right")
	end
    if sg >= 5 then
        love.graphics.printf(self.SGnames[sg], 240, 450, 180, "left")
    end
end

function DeathRoll:getBackground()
	return math.floor(self.level / 100)
end

function DeathRoll:getHighscoreData()
	return {
		level = self.level,
		frames = self.frames,
		grade = self.grade,
	}
end

return DeathRoll
