--[[
######  #    #    ######                           
#     # #   #     #     # #####   ####   ####      
#     # #  #      #     # #    # #    # #          
#     # ###       ######  #    # #    #  ####      
#     # #  #      #     # #####  #    #      # ### 
#     # #   #     #     # #   #  #    # #    # ### 
######  #    #    ######  #    #  ####   ####  ###
PROTOTYPE by 10yard

The arcade version of Donkey Kong is adapted for 2 player co-operative gameplay.
For x64 Windows only. 

1P and 2P controls are configured in MAME UI under "Input Settings > Input Assignments (this system)"
You must exit and restart the game after making control changes.  Changes are then applied to P2 sessions.

Session 1 (foreground) and session 2 (background) are synchronised with data merged into session 1.
]]
local exports = {}
exports.name = "coopkong"
exports.version = "0.2"
exports.description = "DK Bros: Multiplayer Co-Op Donkey Kong"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local coopkong = exports

function coopkong.startplugin()
	local mac, scr, cpu, mem, snd, prt, vid
	local parameters, session, invincible, show2
	local attenuation, frame, hitframe, cleanup
	local status, mode, stage, combined
	local address, offset, size

	local s1, s2, olds1, olds2 = {}, {}, {}, {}  -- session data
	local characters = "0123456789       ABCDEFGHIJKLMNOPQRSTUVWXYZ@-"
	local graphics = {
		"                                                                                                            2     22222          ",
		"                                                                                1      1       1            22   2222222         ",
		"                                     222222                                      2     2      2  222222222222222 2112112         ",
		"                                    23333332                                      3    3     3              22   2112112         ",
		"                                   23      32         2222                         3   3    3               2    2221222         ",
		"                                  23        32       233332            22           3      3                     1122211         ",
		"        3            11111       23          32     23111132          2332                                        12121          ",
		"     1111111        1211111      23          32    231    132        231132                                                      ",
		"    122222121       1111111      23          32    231    132        231132     1233   1    3321                                 ",
		"    111111111      3121111133333 23          32     23111132          2332                                                       ",
		"    111111111       1211111       23        32       233332            22           3      3                                     ",
		"     1111111     2  1211111        23      32         2222                         3   2    3                                    ",
		"        3         2 1211111  2      23333332                                      3    2     3                                   ",
		"        3        2   11111  2        222222                                      2     3      2                                  ",
		"        3       2 222      2  2                                                 1      1       1                                 ",
		"        3                                                                                                                        "}
	local pal_default = {0xff0403ff, 0xfffefcff, 0xffF5bca0}  -- adjusted upright hammer colour for P2
	local pal_expiring = {0xfff4ba15, 0xfffefcff, 0xffe8070a}
	local pal_smash = {0xfffefcff, 0xff0403ff, 0xff14f3ff}
	local pal_arrow = {0xff000000, 0xfffefcff, 0xfff4ba15}
	local destroy_seq = {2, 3, 2, 3, 2, 3, 4, 5, 5, 5, 5}
	local hammer_pos = {{167, 15, 75, 166}, {126, 14, 87, 102}, nil, {127, 6, 167, 103}}
	local rivet_pos = {0x76cb, 0x752b, 0x76d0, 0x7530, 0x76d5, 0x7535, 0x76da, 0x753a}
	
	function initialize()
		--[[
		 ###                                                                      
		  #  #    # # ##### #   ##   #      #  ####    ##   ##### #  ####  #    # 
		  #  ##   # #   #   #  #  #  #      # #       #  #    #   # #    # ##   # 
		  #  # #  # #   #   # #    # #      #  ####  #    #   #   # #    # # #  # 
		  #  #  # # #   #   # ###### #      #      # ######   #   # #    # #  # # 
		  #  #   ## #   #   # #    # #      # #    # #    #   #   # #    # #   ## 
		 ### #    # #   #   # #    # ###### #  ####  #    #   #   #  ####  #    # 
		]]
		if emu.romname() == "dkong" and tonumber(emu.app_version()) >= 0.256 then
			mac = manager.machine
			parameters = manager.options.entries.autoboot_command:value()
			if string.find(parameters, "S1") then session = 1 end
			if string.find(parameters, "S2") then session = 2 end
			if not session then
				mac = nil
				print("ERROR: The session number must be provided.")
			end
		else
			print("ERROR: The coopkong plugin requires Donkey Kong with MAME version 0.256 or greater.")
		end
		if mac ~= nil then
			scr = mac.screens[":screen"]
			cpu = mac.devices[":maincpu"]
			mem = cpu.spaces["program"]
			snd = mac.sound
			vid = mac.video
			prt = mac.ioport.ports
			attenuation = snd.attenuation			
						
			-- Check for other parameters
			if string.find(parameters, "INVINCIBLE") then invincible = 1 end
			if string.find(parameters, "SHOW2") then show2 = 1 end
					
			-- ROM modifications
			write_rom_message(0x36b4, " DK BROS@ ")								-- Mod: Update title
			write_rom_message(0x36ce, "HOW HIGH CAN TWO GET")					-- Mod: Update how high text
			write_rom_message(0x36e8, "  ANY START BUTTON  ")					-- Mod: Start text 1P
			write_rom_message(0x36ff, "  ANY START BUTTON   ")					-- Mod: Start text 2P
			write_data(0x0210, {0x3e, 0x07}) 									-- Mod: Starting lives to 7
			write_data(0x130d, {0x00, 0x90}) 									-- Mod: Disable high score entry
			write_data(0x20b2, {0, 0, 0})										-- Mod: Barrels keep rolling under P1
			write_data(0x2184, {0, 0})											-- Mod: Barrels can take ladders when under P1
			write_rom_message(0x336b, 0)										-- Mod: Fires can go down ladders when P1 is above
			for i=0x096b, 0x0975 do mem:write_direct_u8(i, 0x00) end			-- Mod: Remove high score table
			if invincible == 1 then write_data(0x2813, {0x3e, 0x00, 0x00}) end	-- Mod: Invincible to enemies
				
			-- Mod: Mute session 2 music
			if session == 2 then
				for _, v in ipairs({0x0cd8, 0x0ceb, 0x0cf6, 0x0cbf, 0x0679}) do mem:write_direct_u8(v, 0x00) end
			end
			
			-- open random access session files for data exchange
			f1, f2 = io.open("session/s1.dat", "r+"),  io.open("session/s2.dat", "r+")
		end
	end
	
	function main()
		if cpu ~= nil then
			--[[
			  #####                                                                                        
			 #     # #   # #    #  ####  #    # #####   ####  #    # #  ####    ##   ##### #  ####  #    # 
			 #        # #  ##   # #    # #    # #    # #    # ##   # # #       #  #    #   # #    # ##   # 
			  #####    #   # #  # #      ###### #    # #    # # #  # #  ####  #    #   #   # #    # # #  # 
				   #   #   #  # # #      #    # #####  #    # #  # # #      # ######   #   # #    # #  # # 
			 #     #   #   #   ## #    # #    # #   #  #    # #   ## # #    # #    #   #   # #    # #   ## 
			  #####    #   #    #  ####  #    # #    #  ####  #    # #  ####  #    #   #   #  ####  #    # 
			]]
			mem:write_u8(0x600f, 0)				-- disable the default turn based 2 player game
			mem:write_u8(0x622d, 1)				-- disable extra life at 7000
			if mem:read_u8(0x6001) < 1 then mem:write_direct_u8(0x6001, 1) end -- Enter 1 coin by default
			
			status = mem:read_u8(0x6005)		-- game status (1 attract, 2 coins in, 3 playing)
			mode = mem:read_u8(0x600a)			-- mode
			frame = scr:frame_number()			-- frame number (~60 fps)
			--mem:write_u8(0x6227, 3)			-- force a specific stage
			stage = mem:read_u8(0x6227)			-- active stage (1=barrels, 2=pies, 3=springs, 4=rivets)

			if session == 2 then
				--[[
				  #####                                           #####  
				 #     # ######  ####   ####  #  ####  #    #    #     # 
				 #       #      #      #      # #    # ##   #          # 
				  #####  #####   ####   ####  # #    # # #  #     #####  
					   # #           #      # # #    # #  # #    #       
				 #     # #      #    # #    # # #    # #   ##    #       
				  #####  ######  ####   ####  #  ####  #    #    #######
				]]
				if not show2 then blank_screen() end
				s2["frame"] = frame
				s2["mode"] = mode

				-- Retrieve session 1 info -----------------------------------------------------------------------------
				f1:seek("set")  -- set cursor to start of file
				s1["mode"] = tonumber(f1:read("*line"))			-- mode
				mem:write_u8(0x62b1, f1:read("*line"))			-- bonus timer
				s1["alive"] = tonumber(f1:read("*line"))		-- alive status
				s1["x"] = tonumber(f1:read("*line"))     		-- x position
				s1["y"] = tonumber(f1:read("*line"))     		-- y position
				s1["enemy_hit"] = tonumber(f1:read("*line"))	-- enemy hit
				s1["enemy_hit_b"] = tonumber(f1:read("*line"))	-- enemy hit
				for i=0x6a0c, 0x6a14, 4 do s1["item-"..tostring(i)] = tonumber(f1:read("*line")) end  -- bonus items
				for i=0x6400, 0x649f do mem:write_u8(i, f1:read("*line")) end	-- fires
				for i=0x6500, 0x65ff do mem:write_u8(i, f1:read("*line")) end	-- bouncers and pies
				for i=0x6700, 0x683f do mem:write_u8(i, f1:read("*line")) end	-- barrels (x10)
				for i=0x6280, 0x628f do mem:write_u8(i, f1:read("*line")) end	-- retractable ladders
				for i=0x62a0, 0x62a6 do mem:write_u8(i, f1:read("*line")) end	-- conveyors
				if stage == 3 then
					for i=0x6600, 0x665f do mem:write_u8(i, f1:read("*line")) end	-- elevators (x6)
				end
				f1:flush()
				--------------------------------------------------------------------------------------------------------

				-- Sync P1 dead with P2
				if s1["alive"] == 0 and olds1 and olds1["alive"] == 1 then mem:write_u8(0x6200, 0) end

				-- Slight speed ahead so P2 is waiting for P1
				if s2["mode"] > 6 and s2["mode"] < 12 then
					vid.throttle_rate = 1.1
				else
					vid.throttle_rate = 1
				end
				-- Wait for sync with P1 session
				if s2["mode"] == 12 and s1["mode"] < 12 then
					scr:draw_text(0, 0, "Waiting for sync...", 0xffffffff)
					emu.pause()
				else
					emu.unpause()
				end

				-- mute music and non-gameplay sounds from session 2
				if s2["mode"] ~= 12 then snd.attenuation = -32 else snd.attenuation = attenuation end

				-- Adjust P2 start position
				if s2["mode"] == 12 and olds2 and olds2["mode"] < 12 then mem:write_u8(0x6203, mem:read_u8(0x6203) + 4) end

				-- Remove bonus items collected by P1
				if s1["mode"] == 12 and stage > 1 then
					for i=0x6a0c, 0x6a14, 4 do
						if s1["item-"..tostring(i)] == 0 then mem:write_u8(i, 0) end
					end
				end

				-- Sync P1 finish with P2
				if s2["mode"] == 12 and s1["mode"] == 0x16 then
					mem:write_u8(0x638c, 0)  -- don't award bonus points,  P1 gets the bonus
					mem:write_u8(0x62b1, 0)  -- don't award bonus points,  P1 gets the bonus
					if stage < 4 then
						mem:write_u8(0x6203, s1["x"] + 2)
						mem:write_u8(0x6205, 0x30)
					else
						mem:write_u8(0x6290, 0)
					end
				end

				-- Freeze P2 while P1 is smashing
				if s1["mode"] == 12 and s2["mode"] == 12 and mem:read_u8(0x6350) == 0 and s1["enemy_hit"] == 1 then
					emu.pause()
				else
					emu.unpause()
				end

				-- Store session 2 info --------------------------------------------------------------------------------
				f2:seek("set")  -- set cursor to start of file
				f2:write(s2["mode"].."\n")  -- mode
				f2:write(mem:read_u8(0x6200).."\n")  -- alive status
				f2:write(mem:read_u8(0x6203).."\n")  -- x pos
				f2:write(mem:read_u8(0x6205).."\n")  -- y pos
				f2:write(mem:read_u8(0x694d).."\n")  -- sprite value
				f2:write(mem:read_u8(0x6217).."\n")  -- hammer active
				f2:write(mem:read_u8(0x6218).."\n")  -- hammer grab
				f2:write(mem:read_u8(0x6395).."\n")  -- hammer ending
				f2:write(bool_int(mem:read_u8(0x6a18) > 0 and mem:read_u8(0x6681) == 0).."\n")  -- hammer 1 available
				f2:write(bool_int(mem:read_u8(0x6a1c) > 0 and mem:read_u8(0x6691) == 0).."\n")  -- hammer 2 available
				f2:write(mem:read_u8(0x6350).."\n")  -- enemy hit
				f2:write(mem:read_u8(0x6352).."\n")  -- enemy type
				f2:write(mem:read_u8(0x6354).."\n")  -- enemy no
				for i=0x76e1, 0x7781, 0x20 do f2:write(mem:read_u8(i).."\n") end  -- score
				for i=0x6a30, 0x6a34 do f2:write(mem:read_u8(i).."\n") end  -- points
				for i=0x6292,0x6299 do f2:write(mem:read_u8(i).."\n") end  -- rivets
				for i=0x6a0c, 0x6a14, 4 do f2:write(mem:read_u8(i).."\n") end  -- bonus items
				f2:flush()
				--------------------------------------------------------------------------------------------------------
			end
			
			if session == 1 then
				--[[
				  #####                                            #   
				 #     # ######  ####   ####  #  ####  #    #     ##   
				 #       #      #      #      # #    # ##   #    # #   
				  #####  #####   ####   ####  # #    # # #  #      #   
					   # #           #      # # #    # #  # #      #   
				 #     # #      #    # #    # # #    # #   ##      #   
				  #####  ######  ####   ####  #  ####  #    #    ##### 
				]]
				if mac.paused then emu.unpause() end -- disable session 1 pausing

				s1["frame"] = frame
				s1["mode"] = mode

				-- Retrieve session 2 info --------------------------------------------------------------------------------
				f2:seek("set")  -- set cursor to start of file
				s2["mode"] = tonumber(f2:read("*line"))	          -- mode			
				s2["alive"] = tonumber(f2:read("*line"))          -- alive status
				s2["x"] = tonumber(f2:read("*line"))              -- x position
				s2["y"] = tonumber(f2:read("*line"))              -- y position
				s2["sprite"] = tonumber(f2:read("*line"))         -- sprite value
				s2["hammer_active"] = tonumber(f2:read("*line"))  -- hammer active
				s2["hammer_grab"] = tonumber(f2:read("*line"))    -- hammer grab
				s2["hammer_ending"] = tonumber(f2:read("*line"))  -- hammer ending
				s2["hammer_1_avail"] = tonumber(f2:read("*line")) -- hammer 1 available
				s2["hammer_2_avail"] = tonumber(f2:read("*line")) -- hammer 2 available
				s2["enemy_hit"] = tonumber(f2:read("*line"))      -- enemy hit
				s2["enemy_type"] = tonumber(f2:read("*line"))     -- enemy type
				s2["enemy_no"] = tonumber(f2:read("*line"))       -- enemy no
				for i=0x7481, 0x7521, 0x20 do mem:write_u8(i, f2:read("*line")) end  -- score
				for i=0x6a30, 0x6a34 do s2["points-"..tostring(i)] = tonumber(f2:read("*line")) end  -- points				
				for i=0x6292, 0x6299 do s2["rivet-"..tostring(i)] = tonumber(f2:read("*line")) end   -- rivets
				for i=0x6a0c, 0x6a14, 4 do s2["item-"..tostring(i)] = tonumber(f2:read("*line")) end -- bonus items
				-----------------------------------------------------------------------------------------------------------

				-- Sync P2 dead with P1
				if s2["alive"] == 0 and olds2 and olds2["alive"] == 1 then mem:write_u8(0x6200, 0) end

				-- Wait for sync with P2 session.  This shouldn't really happen.
				if s1["mode"] == 12 and s2["mode"] < 12 then
					scr:draw_text(0, 0, "Waiting for sync...", 0xffffffff)
					snd.attenuation = -32
					vid.throttle_rate = 0.05
				else
					snd.attenuation = attenuation
					vid.throttle_rate = 1
				end

				if status < 3 then display_title() end

				-- display arrows indicating that scores are combined
				if s1["mode"] and s1["mode"] > 0 then
					draw_sprite(6, pal_arrow, 248, 60)
					draw_sprite(6, pal_arrow, 248, 136, 4)
				end

				-- Flashing 2UP in time with 1UP
				if mem:read_u8(0x7740) ~= 0x10 then write_message(0x74e0, "2UP") else write_message(0x74e0, "   ") end
						
				-- Show P2 points scored
				local _points, _oldpoints
				if s2["mode"] == 12 and olds2 then
					for i=0x6a30, 0x6a34 do 
						_points, _oldpoints = s2["points-"..tostring(0x6a30)] or 0, olds2["points-"..tostring(0x6a30)] or 0
						if _points and (tonumber(_points) > 0 or tonumber(_oldpoints) > 0) then 
							mem:write_u8(i, s2["points-"..tostring(i)])
						end
					end
				end
				
				-- Check and remove P2 rivets
				if s2["mode"] == 12 and stage == 4 then -- check and remove P2 rivets
					for i=0x6292,0x6299 do 
						if mem:read_u8(i) == 1 then
							-- Has P2 done this rivet?
							if s2["rivet-"..tostring(i)] == 0 then
								mem:write_u8(i, 0) -- flag rivet as removed
								mem:write_u8(0x6290, mem:read_u8(0x6290) - 1)  -- update rivet count
								mem:write_u8(rivet_pos[i - 0x6291] - 1, 0x10) -- remove rivet from screen (top part)
								mem:write_u8(rivet_pos[i - 0x6291], 0x10) -- remove rivet from screen (bottom part)
							end
						end
					end
				end
				
				-- Remove bonus items collected by P2
				if s2["mode"] == 12 and stage > 1 then
					for i=0x6a0c, 0x6a14, 4 do
						if s2["item-"..tostring(i)] == 0 then mem:write_u8(i, 0) end  -- remove bonus items
					end
				end

				-- Hijack unused sprite from session 1 for player 2 jumpman
				if s1["mode"] > 11 and s1["mode"] < 16 then
					mem:write_u8(0x697c, s2["x"])
					mem:write_u8(0x697f, s2["y"])
					--scr:draw_text(256 - s2["y"], s2["x"] -16, "O", 0xffffffff)  -- Place holder for P2 Jumpman
					mem:write_u8(0x697d, s2["sprite"])				
					mem:write_u8(0x697e, 0x0c)  -- Set Jumpman color to blue
				end
				
				-- Draw available hammers
				if hammer_pos[stage] then
					if s1["mode"] >= 11 and s1["mode"] <= 13 then
						if s2["hammer_1_avail"] == 1 then draw_sprite(0, pal_default, hammer_pos[stage][1], hammer_pos[stage][2]) end
						if s2["hammer_2_avail"] == 1 then draw_sprite(0, pal_default, hammer_pos[stage][3], hammer_pos[stage][4]) end				
					end
				end

				-- Update fire sprite to blue colour when P2 is smashing
				if s1["mode"] == 12 and s2["mode"] == 12 then
					if s2["hammer_active"] == 1 then
						for i=0x69d0, 0x69ef, 0x04 do mem:write_u8(i+2, 0) end
					end
				end
				-- clear any smash sprite remnants
				if s2["enemy_hit"] == 0 and olds2 and olds2["enemy_hit"] == 1 then mem:write_u8(0x6a2d, 0x64) end

				-- Draw hammer when smashing
				if s1["mode"] == 12 and s2["mode"] == 12 and (s2["hammer_active"] == 1 or s2["hammer_grab"] == 1) then
					local _pal = pal_default
					local _hx, _hy = s2["x"] - 23, 269 - s2["y"]
					if s2["hammer_ending"] == 1 then _pal = pal_expiring end
					if s2["hammer_grab"] == 1 then
						draw_sprite(0, _pal, _hy+12, _hx-3)
					elseif s2["sprite"] % 128 >= 8 and s2["sprite"] % 128 <= 13 then
						if s2["sprite"] == 8 or s2["sprite"] == 10 then
							draw_sprite(0, _pal, _hy+12, _hx)
						elseif s2["sprite"] == 12 or s2["sprite"] == 140 then
							draw_sprite(0, _pal, _hy+12, _hx-1)
						elseif s2["sprite"] == 136 or s2["sprite"] == 138 then
							draw_sprite(0, _pal, _hy+12, _hx-2)
						elseif s2["sprite"] == 9 or s2["sprite"] == 11 or s2["sprite"] == 13 then
							draw_sprite(1, _pal, _hy-4, _hx-16)
						elseif s2["sprite"] == 137 or s2["sprite"] == 139 or s2["sprite"] == 141 then
							draw_sprite(1, _pal, _hy-4, _hx+13, 2)
						end
					end
				end

				-- Cleanup previously removed fires and pies
				if cleanup and s2["enemy_hit"] ~= 1 then
					mem:write_u8(cleanup + 3, 250)
					mem:write_u8(cleanup + 5, 8)
					cleanup = nil
				end

				-- Remove enemies hit by P2 hammer
				if s2["enemy_hit"] == 1 then
					address, size = s2["enemy_type"] * 0x100, 0x20
					if s2["enemy_type"] == 0x65 then address, size = 0x65a0, 0x10 end
					offset = address + (s2["enemy_no"] * size)
					if olds2["enemy_hit"] == 0 then
						hitframe = frame
						s2["enemy_x"] = mem:read_u8(offset + 0x03) - 16
						s2["enemy_y"] = mem:read_u8(offset + 0x05)
					end

					mem:write_u8(offset + 0x03, 0)
					mem:write_u8(offset + 0x05, 0)
					if s2["enemy_type"] == 0x64 or s2["enemy_type"] == 0x65 then  -- fires and pies
						mem:write_u8(offset + 0x0e, 0)
						mem:write_u8(offset + 0x0f, 0)
						cleanup = offset
					end

					-- Destruction animation
					draw_sprite(destroy_seq[math.floor((frame - hitframe) / 8) % #destroy_seq + 1], pal_smash, 264 - s2["enemy_y"], s2["enemy_x"] - 8)
				end

				-- Sync P2 finish with P1
				if s1["mode"] == 12 and s2["mode"] == 0x16 then
					mem:write_u8(0x638c, 0)  -- don't award bonus points,  P2 gets the bonus
					mem:write_u8(0x62b1, 0)  -- don't award bonus points,  P2 gets the bonus
					if stage < 4 then mem:write_u8(0x6205, 0x30) else mem:write_u8(0x6290, 0) end	
				end
														
				-- Force delay when player 2 is smashing an enemy
				if s1["mode"] == 12 then
					if s2["enemy_hit"] == 1 then
						mem:write_u8(0x6350, 1)  -- surprised this actually worked!
						mem:write_u8(0x6345, 1)  --"--
						snd.attenuation = -32
					else
						snd.attenuation = attenuation
						if olds2 and olds2["enemy_hit"] == 1 then
							mem:write_u8(0x6350, 0)
							mem:write_u8(0x6345, 0)
						end
					end
				end

				-- Display combined score inplace of high score
				combined = string.format("%07d", tonumber(read_score(0x7781, 6)) + tonumber(read_score(0x7521, 6)))
				if #combined == 7 then write_message(0x7661, combined, 0x70) end				

				-- Store session 1 info --------------------------------------------------------------------------------
				f1:seek("set")  -- set cursor to start of file
				f1:write(s1["mode"].."\n")           -- mode
				f1:write(mem:read_u8(0x62b1).."\n")  -- bonus timer
				f1:write(mem:read_u8(0x6200).."\n")  -- alive status
				f1:write(mem:read_u8(0x6203).."\n")  -- x position
				f1:write(mem:read_u8(0x6205).."\n")  -- y position
				f1:write(mem:read_u8(0x6350).."\n")  -- enemy hit a
				f1:write(mem:read_u8(0x6345).."\n")  -- enemy hit b
				for i=0x6a0c, 0x6a14, 4 do f1:write(mem:read_u8(i).."\n") end	-- bonus items
				for i=0x6400, 0x649f do f1:write(mem:read_u8(i).."\n") end		-- fires
				for i=0x6500, 0x65ff do f1:write(mem:read_u8(i).."\n") end		-- bouncers and pies
				for i=0x6700, 0x683f do f1:write(mem:read_u8(i).."\n") end		-- barrels (x10)
				for i=0x6280, 0x628f do f1:write(mem:read_u8(i).."\n") end		-- retractable ladders
				for i=0x62a0, 0x62a6 do f1:write(mem:read_u8(i).."\n") end		-- conveyors
				for i=0x6600, 0x665f do f1:write(mem:read_u8(i).."\n") end		-- elevators (x6)
				f1:flush()
				--------------------------------------------------------------------------------------------------------
			end
			olds1, olds2 = copy(s1), copy(s2)
		end
	end
	
	--[[
	 #######                                                   
	 #       #    # #    #  ####  ##### #  ####  #    #  ####  
	 #       #    # ##   # #    #   #   # #    # ##   # #      
	 #####   #    # # #  # #        #   # #    # # #  #  ####  
	 #       #    # #  # # #        #   # #    # #  # #      # 
	 #       #    # #   ## #    #   #   # #    # #   ## #    # 
	 #        ####  #    #  ####    #   #  ####  #    #  ####  	
	]]
	
	function display_title()
		local i = ({0, 1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2, 1})[math.floor((frame / 10) % 16) + 1]
		write_message(0x77ad + i, "                            ")
		write_message(0x77ae + i, "++  +  +  +++ +++ +++ +++   ")
		write_message(0x77af + i, "+ + + +   + + + + + + +     ")
		write_message(0x77b0 + i, "+ + ++    ++  ++  + + +++   ")
		write_message(0x77b1 + i, "+ + + +   + + + + + +   + ++")
		write_message(0x77b2 + i, "++  +  +  +++ + + +++ +++ ++")
		write_message(0x77b3 + i, "                            ")
		if frame % 160 < 80 then write_message(0x77bf, "PROTOTYPE B") else write_message(0x77bf, "BY 10YARD  ") end
		-- if frame % 80 < 40 then mem:write_u8(0x6082, 0x01) end  -- Play DK Roar Sound
	end
	
	function blank_screen()
		scr:draw_box(0, 0, 256, 224, 0xff000000, 0xff000000)
	end
	
	function write_data(addr, values)
		for k, v in ipairs(values) do
			mem:write_direct_u8(addr + k - 1, v)
		end
	end
	
	function bool_int(value)
		return value and 1 or 0
	end
	
	function copy(orig)
		local copy = {}
		for orig_key, orig_value in pairs(orig) do copy[orig_key] = orig_value end
		return copy
	end
	
	function draw_sprite(id, palette, y, x, flip)
		local _flip = flip or 0
		local _i, _c
		for k, v in ipairs(graphics) do
			for i=0, 15 do 
				if _flip > 0 then _i = 16 - i else _i = i end
				_c = string.sub(v, (id * 16) + i + 1, (id * 16) + i + 1)
				if _c ~= " " then
					scr:draw_box(y - k, x + _i + _flip, y - k - 1, x + _i + 1 + _flip, palette[tonumber(_c)], palette[tonumber(_c)])
				end
			end
		end
	end
	
	function read_score(start_addr, length)
		-- read score from video ram
		local text = ""
		for i=start_addr, start_addr - (0x20 * length - 1), -0x20 do
			text = text..tostring(mem:read_u8(i))
		end
		return text
	end
	
	function write_message(start_addr, text, adjust)
		-- write characters of message to video ram
		local _adjust = adjust or 0
		local _p
		for key=1, string.len(text) do
			_p = string.find(characters, string.sub(text, key, key))
			if _p and _p > 0 then
				mem:write_u8(start_addr - ((key - 1) * 32), _p - 1 + _adjust)
			else
				mem:write_u8(start_addr - ((key - 1) * 32), 0xb0)
			end
		end
	end	
	
	function write_rom_message(start_addr, text)
		-- write characters of message to ROM
		for key=1, string.len(text) do
			mem:write_direct_u8(start_addr + (key - 1), string.find(characters, string.sub(text, key, key)) - 1)
		end
	end	
	
	emu.add_machine_reset_notifier(function()	
		initialize()
	end)

	emu.add_machine_stop_notifier(function()
		f1:close()
		f2:close()
	end)
	
	emu.register_frame_done(main, "frame")
end
return exports