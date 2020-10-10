require 'funcs'

local GameMode = require 'tetris.modes.gamemode'
local Piece = require 'tetris.components.piece'

local History6RollsRandomizer = require 'tetris.randomizers.history_6rolls_35bag'

local MarathonA3Game = GameMode:extend()

MarathonA3Game.name = "Marathon A3"
MarathonA3Game.hash = "MarathonA3"
MarathonA3Game.tagline = "The game gets faster way more quickly! Can you get all the Section COOLs?"




function MarathonA3Game:new()
    MarathonA3Game.super:new()

    presence.details = "Playing Marathon A3"
    
  	discordRPC.updatePresence(presence)

    self.ready_frames = 120

    self.speed_level = 0
	self.roll_frames = 0
    self.combo = 1
	self.grade = 0
	self.grade_points = 0
	self.roll_points = 0
	self.grade_point_decay_counter = 0
	self.section_cool_grade = 0
	self.section_status = { [0] = "none" }
	self.section_start_time = 0
	self.section_70_times = { [0] = 0 }
	self.section_times = { [0] = 0 }

	self.randomizer = History6RollsRandomizer()

    self.lock_drop = true
    self.lock_hard_drop = true
	self.enable_hold = true
	self.next_queue_length = 3

	self.coolregret_message = "COOL!!"
	self.coolregret_timer = 0
end

function MarathonA3Game:getARE()
        if self.speed_level < 700 then return 27
    elseif self.speed_level < 800 then return 18
    elseif self.speed_level < 1000 then return 14
    elseif self.speed_level < 1100 then return 8
    elseif self.speed_level < 1200 then return 7
    else return 6 end
end

function MarathonA3Game:getLineARE()
        if self.speed_level < 600 then return 27
    elseif self.speed_level < 700 then return 18
    elseif self.speed_level < 800 then return 14
    elseif self.speed_level < 1100 then return 8
    elseif self.speed_level < 1200 then return 7
    else return 6 end
end

function MarathonA3Game:getDasLimit()
        if self.speed_level < 500 then return 15
    elseif self.speed_level < 900 then return 9
    else return 7 end
end

function MarathonA3Game:getLineClearDelay()
        if self.speed_level < 500 then return 40
    elseif self.speed_level < 600 then return 25
    elseif self.speed_level < 700 then return 16
    elseif self.speed_level < 800 then return 12
    elseif self.speed_level < 1100 then return 6
    elseif self.speed_level < 1200 then return 5
    else return 4 end
end

function MarathonA3Game:getLockDelay()
        if self.speed_level < 900 then return 30
    elseif self.speed_level < 1100 then return 17
    else return 15 end
end

function MarathonA3Game:getGravity()
        if (self.speed_level < 30)  then return 4/256
    elseif (self.speed_level < 35)  then return 6/256
    elseif (self.speed_level < 40)  then return 8/256
    elseif (self.speed_level < 50)  then return 10/256
    elseif (self.speed_level < 60)  then return 12/256
    elseif (self.speed_level < 70)  then return 16/256
    elseif (self.speed_level < 80)  then return 32/256
    elseif (self.speed_level < 90)  then return 48/256
    elseif (self.speed_level < 100) then return 64/256
    elseif (self.speed_level < 120) then return 80/256
    elseif (self.speed_level < 140) then return 96/256
    elseif (self.speed_level < 160) then return 112/256
    elseif (self.speed_level < 170) then return 128/256
    elseif (self.speed_level < 200) then return 144/256
    elseif (self.speed_level < 220) then return 4/256
    elseif (self.speed_level < 230) then return 32/256
    elseif (self.speed_level < 233) then return 64/256
    elseif (self.speed_level < 236) then return 96/256
    elseif (self.speed_level < 239) then return 128/256
    elseif (self.speed_level < 243) then return 160/256
    elseif (self.speed_level < 247) then return 192/256
    elseif (self.speed_level < 251) then return 224/256
    elseif (self.speed_level < 300) then return 1
    elseif (self.speed_level < 330) then return 2
    elseif (self.speed_level < 360) then return 3
    elseif (self.speed_level < 400) then return 4
    elseif (self.speed_level < 420) then return 5
    elseif (self.speed_level < 450) then return 4
    elseif (self.speed_level < 500) then return 3
    else return 20
    end
end

function MarathonA3Game:advanceOneFrame()
	if self.clear then
		self.roll_frames = self.roll_frames + 1
		if self.roll_frames < 0 then
			if self.roll_frames + 1 == 0 then
				switchBGM("credit_roll", "gm3")
			end
			return false
		elseif self.roll_frames > 3238 then
			if self:qualifiesForMRoll() then
				self.roll_points = self.roll_points + 160
			else
				self.roll_points = self.roll_points + 50
			end
			switchBGM(nil)
			self.completed = true
		end
	elseif self.ready_frames == 0 then
		self.frames = self.frames + 1
	end
	return true
end

function MarathonA3Game:onPieceEnter()
	if (self.level % 100 ~= 99) and self.level ~= 998 and self.frames ~= 0 then
        self:updateSectionTimes(self.level, self.level + 1)
        self.level = self.level + 1
        self.speed_level = self.speed_level + 1
    end
end

local cleared_row_levels = {1, 2, 4, 6}

function MarathonA3Game:onLineClear(cleared_row_count)
    local advanced_levels = cleared_row_levels[cleared_row_count]
    self:updateSectionTimes(self.level, self.level + advanced_levels)
    if not self.clear then
        self.level = math.min(self.level + advanced_levels, 999)
    end
    self.speed_level = self.speed_level + advanced_levels
    if self.level == 999 and not self.clear then
        self.clear = true
        self.grid:clear()
        self.roll_frames = -150
    end
end

local cool_cutoffs = {
	frameTime(0,52), frameTime(0,52), frameTime(0,49), frameTime(0,45), frameTime(0,45),
	frameTime(0,42), frameTime(0,42), frameTime(0,38), frameTime(0,38),
}

local regret_cutoffs = {
	frameTime(0,90), frameTime(0,75), frameTime(0,75), frameTime(0,68), frameTime(0,60),
	frameTime(0,60), frameTime(0,50), frameTime(0,50), frameTime(0,50), frameTime(0,50),
}

function MarathonA3Game:updateSectionTimes(old_level, new_level)
	if self.clear then return end
	local section = math.floor(old_level / 100) + 1
	if math.floor(old_level / 100) < math.floor(new_level / 100) or
	new_level >= 999 then
		-- record new section
		section_time = self.frames - self.section_start_time
		table.insert(self.section_times, section_time)
		self.section_start_time = self.frames

		if section_time > regret_cutoffs[section] then
			self.section_cool_grade = self.section_cool_grade - 1
			table.insert(self.section_status, "regret")
			self.coolregret_message = "REGRET!!"
			self.coolregret_timer = 300
		elseif section <= 9 and self.section_status[section - 1] == "cool" and
		self.section_70_times[section] < self.section_70_times[section - 1] + 120 then
			self.section_cool_grade = self.section_cool_grade + 1
			self.speed_level = self.speed_level + 100
			table.insert(self.section_status, "cool")
			self.coolregret_message = "COOL!!"
			self.coolregret_timer = 300
		elseif self.section_status[section - 1] == "cool" then
			table.insert(self.section_status, "none")
		elseif section <= 9 and self.section_70_times[section] < cool_cutoffs[section] then
			self.section_cool_grade = self.section_cool_grade + 1
			self.speed_level = self.speed_level + 100
			table.insert(self.section_status, "cool")
			self.coolregret_message = "COOL!!"
			self.coolregret_timer = 300
		else
			table.insert(self.section_status, "none")
		end
	elseif section <= 9 and old_level % 100 < 70 and new_level % 100 >= 70 then
		-- record section 70 time
		section_70_time = self.frames - self.section_start_time
		table.insert(self.section_70_times, section_70_time)
	end
end

function MarathonA3Game:updateScore(level, drop_bonus, cleared_lines)
    self:updateGrade(cleared_lines)
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

local grade_point_bonuses = {
	{10, 20, 40, 50},
	{10, 20, 30, 40},
	{10, 20, 30, 40},
	{10, 15, 30, 40},
	{10, 15, 20, 40},
	{5, 15, 20, 30},
	{5, 10, 20, 30},
	{5, 10, 15, 30},
	{5, 10, 15, 30},
	{5, 10, 15, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
	{2, 12, 13, 30},
}

local grade_point_decays = {
	125, 80, 80, 50, 45, 45, 45,
	40, 40, 40, 40, 40, 30, 30, 30,
	20, 20, 20, 20, 20,
	15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
	10, 10
}

local combo_multipliers = {
	{1.0, 1.0, 1.0, 1.0},
	{1.0, 1.2, 1.4, 1.5},
	{1.0, 1.2, 1.5, 1.8},
	{1.0, 1.4, 1.6, 2.0},
	{1.0, 1.4, 1.7, 2.2},
	{1.0, 1.4, 1.8, 2.3},
	{1.0, 1.4, 1.9, 2.4},
	{1.0, 1.5, 2.0, 2.5},
	{1.0, 1.5, 2.1, 2.6},
	{1.0, 2.0, 2.5, 3.0},
}

local roll_points = {4, 8, 12, 26}
local mroll_points = {10, 20, 30, 100}

local grade_conversion = {
	[0] = 0,
	1, 2, 3, 4, 5, 5, 6, 6, 7, 7,
	7, 8, 8, 8, 9, 9, 9, 10, 11, 12, 12,
	12, 12, 13, 13, 14, 14, 15, 15, 16, 16,
	17
}

function MarathonA3Game:updateGrade(cleared_lines)
	if cleared_lines == 0 then
		self.grade_point_decay_counter = self.grade_point_decay_counter + 1
		if self.grade_point_decay_counter >= grade_point_decays[self.grade + 1] then
			self.grade_point_decay_counter = 0
			self.grade_points = math.max(0, self.grade_points - 1)
		end
	else
		if self.clear then
			if self:qualifiesForMRoll() then
				self.roll_points = self.roll_points + mroll_points[cleared_lines]
			else
				self.roll_points = self.roll_points + roll_points[cleared_lines]
			end
		else
			self.grade_points = self.grade_points + (
				math.ceil(
					grade_point_bonuses[self.grade + 1][cleared_lines] *
					combo_multipliers[math.min(self.combo, 10)][cleared_lines]
				) * (1 + math.floor(self.level / 250))
			)
			if self.grade_points >= 100 and self.grade < 31 then
				self.grade_points = 0
				self.grade = self.grade + 1
			end
		end
	end
end

function MarathonA3Game:qualifiesForMRoll()
	return self.grade >= 27 and self.section_cool_grade >= 9
end

function MarathonA3Game:getAggregateGrade()
	return self.section_cool_grade + math.floor(self.roll_points / 100) + grade_conversion[self.grade]
end

local master_grades = { "M", "MK", "MV", "MO", "MM" }

function MarathonA3Game:getLetterGrade()
	local grade = self:getAggregateGrade()
	if grade < 9 then
		return tostring(9 - grade)
	elseif grade < 18 then
		return "S" .. tostring(grade - 8)
	elseif grade < 27 then
		return "M" .. tostring(grade - 17)
	elseif grade < 32 then
		return master_grades[grade - 26]
	else
		return "GM"
	end
end

function MarathonA3Game:drawGrid()
	if self.clear and not (self.completed or self.game_over) then
		if self:qualifiesForMRoll() then
			self.grid:drawInvisible(self.mRollOpacityFunction)
		else
			self.grid:drawInvisible(self.rollOpacityFunction)
		end
	else
		self.grid:draw()
		if self.piece ~= nil and self.level < 100 then
			self:drawGhostPiece(ruleset)
		end
	end
end

MarathonA3Game.rollOpacityFunction = function(age)
	if age < 240 then return 1
	elseif age > 300 then return 0
	else return 1 - (age - 240) / 60 end
end

MarathonA3Game.mRollOpacityFunction = function(age)
	if age > 4 then return 0
	else return 1 - age / 4 end
end

function MarathonA3Game:drawScoringInfo()
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.setFont(font_3x5_2)
	love.graphics.print(
		self.das.direction .. " " ..
		self.das.frames .. " " ..
		strTrueValues(self.prev_inputs)
	)
	love.graphics.printf("NEXT", 64, 40, 40, "left")
	love.graphics.printf("GRADE", 240, 120, 40, "left")
	love.graphics.printf("SCORE", 240, 200, 40, "left")
	love.graphics.printf("LEVEL", 240, 320, 40, "left")
	local sg = self.grid:checkSecretGrade()
    if sg >= 5 then
        love.graphics.printf("SECRET GRADE", 240, 430, 180, "left")
    end

	-- draw section time data
	current_section = math.floor(self.level / 100) + 1

	section_x = 530
	section_70_x = 440

	for section, time in pairs(self.section_times) do
		if section > 0 then
			love.graphics.printf(formatTime(time), section_x, 40 + 20 * section, 90, "left")
		end
	end

	for section, time in pairs(self.section_70_times) do
		if section > 0 then
			love.graphics.printf(formatTime(time), section_70_x, 40 + 20 * section, 90, "left")
		end
	end

	local current_x
	if table.getn(self.section_times) < table.getn(self.section_70_times) then
		current_x = section_x
	else
		current_x = section_70_x
	end

	love.graphics.printf(formatTime(self.frames - self.section_start_time), current_x, 40 + 20 * current_section, 90, "left")

	if(self.coolregret_timer > 0) then
                love.graphics.printf(self.coolregret_message, 64, 400, 160, "center")
                self.coolregret_timer = self.coolregret_timer - 1
        end

	love.graphics.setFont(font_3x5_3)
	love.graphics.printf(self.score, 240, 220, 90, "left")
	love.graphics.printf(self:getLetterGrade(), 240, 140, 90, "left")
	love.graphics.printf(self.level, 240, 340, 40, "right")
	love.graphics.printf(self:getSectionEndLevel(), 240, 370, 40, "right")
	if sg >= 5 then
        love.graphics.printf(self.SGnames[sg], 240, 450, 180, "left")
    end

	love.graphics.setFont(font_8x11)
	love.graphics.printf(formatTime(self.frames), 64, 420, 160, "center")
end

function MarathonA3Game:getHighscoreData()
	return {
		grade = self:getAggregateGrade(),
		level = self.level,
		frames = self.frames,
	}
end

function MarathonA3Game:getSectionEndLevel()
	if self.level >= 900 then return 999
	else return math.floor(self.level / 100 + 1) * 100 end
end

function MarathonA3Game:getBackground()
	return math.floor(self.level / 100)
end

return MarathonA3Game
