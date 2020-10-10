bgm = {
	credit_roll = {
		gm3 = love.audio.newSource("res/bgm/tgm_credit_roll.mp3", "stream"),
	},
	pacer_test = love.audio.newSource("res/bgm/pacer_test.mp3", "stream"),
	death_roll = love.audio.newSource("res/bgm/death_roll.mp3", "stream"),
}

local current_bgm = nil
local bgm_locked = false

function switchBGM(sound, subsound)
	if bgm_locked then return end
	if current_bgm ~= nil then
		current_bgm:stop()
	end
	if subsound ~= nil then
		current_bgm = bgm[sound][subsound]
		resetBGMFadeout()
	elseif sound ~= nil then
		current_bgm = bgm[sound]
		resetBGMFadeout()
	else
		current_bgm = nil
	end
end

function switchBGMLoop(sound, subsound)
	if bgm_locked then return end
	switchBGM(sound, subsound)
	current_bgm:setLooping(true)
end

function lockBGM()
	bgm_locked = true
end

local fading_bgm = false
local fadeout_time = 0
local total_fadeout_time = 0

function fadeoutBGM(time)
	if fading_bgm == false then
		fading_bgm = true
		fadeout_time = time
		total_fadeout_time = time
	end
end

function resetBGMFadeout(time)
	current_bgm:setVolume(1)
	fading_bgm = false
	current_bgm:play()
end

function processBGMFadeout(dt)
	if fading_bgm then
		fadeout_time = fadeout_time - dt
		if fadeout_time < 0 then
			fadeout_time = 0
			fading_bgm = false
		end
		current_bgm:setVolume(fadeout_time / total_fadeout_time)
	end
end

function pauseBGM()
	if current_bgm ~= nil then
		current_bgm:pause()
	end
end

function resumeBGM()
	if current_bgm ~= nil then
		current_bgm:play()
	end
end
