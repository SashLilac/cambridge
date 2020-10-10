local ModeSelectScene = Scene:extend()

ModeSelectScene.title = "Game Start"

current_mode = 1
current_ruleset = 1

game_modes = {
	require 'tetris.modes.marathon_2020',
	require 'tetris.modes.survival_2020',
	--require 'tetris.modes.strategy',
	--require 'tetris.modes.interval_training',
	--require 'tetris.modes.pacer_test',
	require 'tetris.modes.demon_mode',
	require 'tetris.modes.phantom_mania',
	require 'tetris.modes.phantom_mania2',
	require 'tetris.modes.phantom_mania_n',
	require 'tetris.modes.race_40',
	require 'tetris.modes.marathon_a1',
	require 'tetris.modes.marathon_a2',
	require 'tetris.modes.marathon_a3',
	require 'tetris.modes.marathon_ax4',
	require 'tetris.modes.marathon_c89',
	require 'tetris.modes.survival_a1',
	require 'tetris.modes.survival_a2',
	require 'tetris.modes.survival_a3',
	require 'tetris.modes.big_a2',
	require 'tetris.modes.konoha',
	require 'tetris.modes.death_roll',
}

rulesets = {
	require 'tetris.rulesets.cambridge',
	require 'tetris.rulesets.arika',
	require 'tetris.rulesets.arika_ti',
	require 'tetris.rulesets.ti_srs',
	require 'tetris.rulesets.arika_ace',
	require 'tetris.rulesets.arika_srs',
	require 'tetris.rulesets.standard_exp',
	--require 'tetris.rulesets.bonkers',
	--require 'tetris.rulesets.shirase',
	--require 'tetris.rulesets.super302',
}

function ModeSelectScene:new()
	self.menu_state = {
		mode = current_mode,
		ruleset = current_ruleset,
		select = "mode",
	}
	presence.details = "In menus"
	presence.state = "Choosing a mode"
	discordRPC.updatePresence(presence)
end

function ModeSelectScene:update()
end

function ModeSelectScene:render()
	love.graphics.draw(
		backgrounds[0],
		0, 0, 0,
		0.5, 0.5
	)

	if self.menu_state.select == "mode" then
		love.graphics.setColor(1, 1, 1, 0.5)
	elseif self.menu_state.select == "ruleset" then
		love.graphics.setColor(1, 1, 1, 0.25)
	end
	love.graphics.rectangle("fill", 20, 78 + 20 * self.menu_state.mode, 240, 22)

	if self.menu_state.select == "mode" then
		love.graphics.setColor(1, 1, 1, 0.25)
	elseif self.menu_state.select == "ruleset" then
		love.graphics.setColor(1, 1, 1, 0.5)
	end
	love.graphics.rectangle("fill", 340, 78 + 20 * self.menu_state.ruleset, 200, 22)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(misc_graphics["select_mode"], 20, 40)

	love.graphics.setFont(font_3x5_2)
	for idx, mode in pairs(game_modes) do
		love.graphics.printf(mode.name, 40, 80 + 20 * idx, 200, "left")
	end
	for idx, ruleset in pairs(rulesets) do
		love.graphics.printf(ruleset.name, 360, 80 + 20 * idx, 160, "left")
	end
end

function ModeSelectScene:onKeyPress(e)
	if e.scancode == "return" and e.isRepeat == false then
		current_mode = self.menu_state.mode
		current_ruleset = self.menu_state.ruleset
		config.current_mode = current_mode
		config.current_ruleset = current_ruleset
		playSE("mode_decide")
		saveConfig()
		scene = GameScene(game_modes[self.menu_state.mode], rulesets[self.menu_state.ruleset])
	elseif (e.scancode == config.input["up"] or e.scancode == "up") and e.isRepeat == false then
		self:changeOption(-1)
		playSE("cursor")
	elseif (e.scancode == config.input["down"] or e.scancode == "down") and e.isRepeat == false then
		self:changeOption(1)
		playSE("cursor")
	elseif (e.scancode == config.input["left"] or e.scancode == "left") or
		(e.scancode == config.input["right"] or e.scancode == "right") then
		self:switchSelect()
		playSE("cursor_lr")
    elseif e.scancode == "escape" then
        scene = TitleScene()
	end
end

function ModeSelectScene:changeOption(rel)
	if self.menu_state.select == "mode" then
		self:changeMode(rel)
	elseif self.menu_state.select == "ruleset" then
		self:changeRuleset(rel)
	end
end

function ModeSelectScene:switchSelect(rel)
	if self.menu_state.select == "mode" then
		self.menu_state.select = "ruleset"
	elseif self.menu_state.select == "ruleset" then
		self.menu_state.select = "mode"
	end
end

function ModeSelectScene:changeMode(rel)
	local len = table.getn(game_modes)
	self.menu_state.mode = (self.menu_state.mode + len + rel - 1) % len + 1
end

function ModeSelectScene:changeRuleset(rel)
	local len = table.getn(rulesets)
	self.menu_state.ruleset = (self.menu_state.ruleset + len + rel - 1) % len + 1
end

return ModeSelectScene
