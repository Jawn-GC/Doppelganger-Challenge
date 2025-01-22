meta = {
    name = "Doppelganger Challenge",
	description = "Outrun spelunker ghosts that copy your movement and deal damage on contact.",
    version = '1.1',
    author = 'JawnGC',
}

register_option_int("n", "Number of ghosts (1 to 5)", 3, 1, 5)
register_option_int("delay", "Seconds of lag between each ghost (1 to 5)", 2, 1, 5)
register_option_bool("sfx_off", "Turn off ghost spawn sound effect", false)
register_option_bool("vanish", "Ghosts will disappear after being touched", true)

local sound = require('play_sound')

local frames = 0
local player_info = {} --elements are {x, y, layer, texture, animation frame, direction facing}
local clones = {}
local i_frames = 0
local pipes = {}
local osiris = {}
local hundun = {}
local world_particles = {}
local ghost_touched = {}
set_callback(function ()	
	
	if #players ~= 0 then
		local px, py, pl = get_position(players[1].uid)
		local pt = players[1]:get_texture()
		local pa = players[1].animation_frame
		local pf = test_flag(players[1].flags, ENT_FLAG.FACING_LEFT)
		table.insert(player_info, 1, {px, py, pl, pt, pa, pf})
	end
	
	if frames == 0 then
		if options.delay < 1 then
			options.delay = 1
		elseif options.delay > 5 then
			options.delay = 5
		end
		
		if options.n < 1 then
			options.n = 1
		elseif options.n > 5 then
			options.n = 5
		end

		pipes = get_entities_by(ENT_TYPE.FLOOR_PIPE, MASK.ANY, LAYER.BOTH)

		for i = 1,options.n do
			clones[#clones + 1] = spawn(ENT_TYPE.ITEM_ROCK, player_info[1][1], player_info[1][2], player_info[1][3], 0, 0)
			ghost_touched[#ghost_touched + 1] = false
		end

		for i = 1,#clones do
			get_entity(clones[i]).flags = set_flag(get_entity(clones[i]).flags,ENT_FLAG.PAUSE_AI_AND_PHYSICS)
			get_entity(clones[i]).flags = clr_flag(get_entity(clones[i]).flags,ENT_FLAG.PICKUPABLE)
			get_entity(clones[i]):set_texture(player_info[1][4])
			get_entity(clones[i]).animation_frame = player_info[1][5]
			get_entity(clones[i]).color.a = 0
		end
	end
	
	if state.theme == THEME.DUAT then
		osiris = get_entities_by(ENT_TYPE.MONS_OSIRIS_HEAD, MASK.ANY, LAYER.BOTH)
	end
	if state.theme == THEME.DUAT and #osiris > 0 and get_entity(clones[1]) ~= nil and test_flag(get_entity(osiris[1]).flags, ENT_FLAG.DEAD) then
		for i = 1,options.n do
			generate_world_particles(PARTICLEEMITTER.ALTAR_SMOKE, clones[options.n + 1 - i])
			get_entity(clones[options.n + 1 - i]).flags = clr_flag(get_entity(clones[options.n + 1 - i]).flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) 
			get_entity(clones[options.n + 1 - i]):destroy()
		end
		if options.sfx_off ~= true then
			sound.play_sound(VANILLA_SOUND.SHARED_SMOKE_TELEPORT)
		end
	end

	if state.theme == THEME.HUNDUN then
		hundun = get_entities_by(ENT_TYPE.MONS_HUNDUN, MASK.ANY, LAYER.BOTH)
	end
	if state.theme == THEME.HUNDUN and #hundun > 0 and get_entity(clones[1]) ~= nil and get_entity(hundun[1]).birdhead_defeated and get_entity(hundun[1]).snakehead_defeated then
		for i = 1,options.n do
			generate_world_particles(PARTICLEEMITTER.ALTAR_SMOKE, clones[options.n + 1 - i])
			get_entity(clones[options.n + 1 - i]).flags = clr_flag(get_entity(clones[options.n + 1 - i]).flags, ENT_FLAG.PAUSE_AI_AND_PHYSICS) 
			get_entity(clones[options.n + 1 - i]):destroy()
		end
		if options.sfx_off ~= true then
			sound.play_sound(VANILLA_SOUND.SHARED_SMOKE_TELEPORT)
		end
	end
	
	for i = 1,#clones do
		local threshold = options.delay * 60 * i
		
		if frames == threshold then
			get_entity(clones[i]).color.a = 0.7
			generate_world_particles(PARTICLEEMITTER.ALTAR_SMOKE, clones[i])
			
			if test_flag(state.level_flags, 18) then
				world_particles[#world_particles + 1] = generate_world_particles(PARTICLEEMITTER.TORCHFLAME_FLAMES, clones[i])
			end
			
			if options.sfx_off ~= true then
				sound.play_sound(VANILLA_SOUND.SHARED_SMOKE_TELEPORT)
			end
		end

		if #player_info >= threshold and get_entity(clones[i]) ~= nil then
			get_entity(clones[i]).x = player_info[threshold][1]
			get_entity(clones[i]).y = player_info[threshold][2]
			get_entity(clones[i]):set_layer(player_info[threshold][3])
			get_entity(clones[i]):set_texture(player_info[threshold][4])
			get_entity(clones[i]).animation_frame = player_info[threshold][5]
			if player_info[threshold][6] then
				get_entity(clones[i]).flags = set_flag(get_entity(clones[i]).flags, ENT_FLAG.FACING_LEFT)
			else
				get_entity(clones[i]).flags = clr_flag(get_entity(clones[i]).flags, ENT_FLAG.FACING_LEFT)
			end
		end

		if #players ~= 0 and get_entity(clones[i]) ~= nil and players[1]:overlaps_with(get_entity(clones[i])) and players[1].layer == get_entity(clones[i]).layer and players[1].state ~= CHAR_STATE.ENTERING and players[1].state ~= CHAR_STATE.EXITING and frames > threshold and i_frames == 0 and ghost_touched[i] == false then
			players[1]:damage(-1, 1, 0, 0, 0, 60)
			i_frames = 60
			if options.vanish == true then
				ghost_touched[i] = true
				get_entity(clones[i]).color.a = 0
				generate_world_particles(PARTICLEEMITTER.ALTAR_SMOKE, clones[i])
				if test_flag(state.level_flags, 18) then
					extinguish_particles(world_particles[i])
				end
				if options.sfx_off ~= true then
					sound.play_sound(VANILLA_SOUND.SHARED_SMOKE_TELEPORT)
				end
			end
		end
		
		if #players ~= 0 and (players[1].state == CHAR_STATE.ENTERING or players[1].state == CHAR_STATE.EXITING) then
			i_frames = 60
		end
	end

	if #players ~= 0 and i_frames > 0 then
		i_frames = i_frames - 1
	end

	frames = frames + 1
end, ON.FRAME)

set_callback(function ()	
	frames = 0
	i_frames = 0
	clones = {}
	player_info = {}
	pipes = {}
	osiris = {}
	hundun = {}
	world_particles = {}
	ghost_touched = {}
end, ON.PRE_LEVEL_GENERATION)