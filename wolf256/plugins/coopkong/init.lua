--[[
OOOOOO   O    O    OOOOOO
O     O  O   O     O     O  OOOOO    OOOO    OOOO
O     O  O  O      O     O  O    O  O    O  O
O     O  OOO       OOOOOO   O    O  O    O   OOOO
O     O  O  O      O     O  OOOOO   O    O       O  OO
OOOOOO   O    O    OOOOOO   O    O   OOOO    OOOO   OO
2 Player co-op Donkey Kong
PROTOTYPE I by 10yard

The arcade version of Donkey Kong is adapted for 2 player co-operative gameplay.
For x64 Windows only. 

1P and 2P controls are configured in MAME UI under "Input Settings > Input Assignments (this system)"
You must exit and restart the game after making control changes.  Changes are then applied to P2 session.

Session 1 (foreground) and session 2 (background) are synchronised - data is merged into session 1.
]]
local exports = {}
exports.name = "coopkong"
exports.version = "0.9"
exports.description = "DK Bros: Multiplayer Co-Op Donkey Kong"
exports.license = "GNU GPLv3"
exports.author = { name = "Jon Wilson (10yard)" }
local coopkong = exports

function coopkong.startplugin()
	local mac, scr, cpu, mem, snd, vid
	local parameters, session, invincible, show2, audit
	local frame, cleanup
	local status, mode, stage, combined
	local address, offset, size
	local exitframe = 0
    local active_steerer, steer_sprite = 1, 0x62

	local s1, s2, olds1, olds2 = {}, {}, {}, {}  -- session data
	local characters = "0123456789       ABCDEFGHIJKLMNOPQRSTUVWXYZ@-"
	local rivet_pos = {0x76cb, 0x752b, 0x76d0, 0x7530, 0x76d5, 0x7535, 0x76da, 0x753a}
	local spawn_table = {{0xee,0xf0}, {0xdb,0xa0}, {0xe6,0xc8}, {0xd6,0x78}, {0x1b,0xc8}, {0x23,0xa0}, {0x2b,0x78}, {0x12,0xf0}}
	local palette = {0xfffefcff, 0xffffffff, 0xfff4ba15}
	local graphics = {
		"           1    ",
		"           11   ",
		"  1111111111111 ",
		"           11   ",
		"           1    "}

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
			att = snd.attenuation

			-- Check for other parameters
			if string.find(parameters, "INVINCIBLE") then invincible = 1 end
			if string.find(parameters, "SHOW2") then show2 = 1 end
			if string.find(parameters, "AUDIT") then audit = 1 end

			-- ROM modifications
			write_rom_message(0x36b4, " DK BROS@ ")								-- Mod: Update title
			write_rom_message(0x36ce, "HOW HIGH CAN TWO GET")					-- Mod: Update how high text
			write_rom_message(0x36e8, "  ANY START BUTTON  ")					-- Mod: Start text 1P
			write_rom_message(0x36ff, "  ANY START BUTTON   ")					-- Mod: Start text 2P
			write_data(0x0210, {0x3e, 0x07}) 									-- Mod: Starting lives to 7
			write_data(0x130d, {0x00, 0x90}) 									-- Mod: Disable high score entry
			write_data(0x20aa, {0x02, 0x61})									-- Mod: Barrel logic. Roll to lowest player (in 0x6102)
			write_data(0x2180, {0x02, 0x61})									-- Mod: Barrels logic. Can take ladders until lowest player
			write_data(0x3364, {0x02, 0x61})									-- Mod: Fires logic. Fires track both players.
			write_data(0x057a, {0xff, 0xff})		  							-- Mod: Remove high score to prevent flicker
			write_data(0x34bf, {0xdd, 0xe5, 0xe1, 0x22, 0x07, 0x61, 0x00, 0x00})-- Mod: Store fireball spawning address (in 0x6107 as 16bit)
			for i=0x096b, 0x0975 do mem:write_direct_u8(i, 0x00) end			-- Mod: Remove high score table
			write_data(0x08de, {0x00, 0x00, 0x00})							    -- Mod: 1 credit is enough for 1 or 2 player start
			write_data(0x0902, {0xca, 0x06, 0x09})							    -- Mod: 2P start button does same as 1P start button

            -- Mod: Steering can switch between P1 and P2 based on content of 0x6103 (X pos), 0x6104 (Input State)
            write_data(0x2198, {0x03, 0x61})
            write_data(0x2195, {0x04, 0x61})

			-- Mod: set default fireball spawning positions on rivets
			write_data(0x3ac4, {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff})
			write_data(0x3ad4, {0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff})

			if invincible == 1 then write_data(0x2813, {0x3e, 0x00, 0x00}) end	-- Mod: Invincible to enemies

			if session == 2 then
				-- Mod: Mute session 2 music
				for _, v in ipairs({0x0cd8, 0x0ceb, 0x0cf6, 0x0cbf, 0x0679}) do mem:write_direct_u8(v, 0x00) end

				-- Adjust player 2 start positions for session 2
				write_data(0x1249, {0x42})  -- pies
				write_data(0x1243, {0x19})  -- all other stages

				-- Adjusted hammer positions for session 2 (x+1, y-1)
				write_data(0x3e0c, {0x25, 0x63, 0xbc, 0xbf, 0x24, 0x8c, 0x7c, 0xb3, 0x1c, 0x8b, 0x7d, 0x63})
			end

			-- open random access session files for data exchange
			f1, f2 = io.open("session/s1.dat", "r+"),  io.open("session/s2.dat", "r+")

			-- optional performance audit to csv file
			if audit == 1 then
				pa1, pa2 = io.open("session/perf1.csv", "w"), io.open("session/perf2.csv", "w")
				pa1:write("frame,stage,mode,expected speed,actual speed,difference\n")
				pa2:write("frame,stage,mode,expected speed,actual speed,difference\n")
			end
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
			--mem:write_u8(0x6229, 3)           -- force a specific level
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
				for i=0x74e6, 0x7486, -0x20 do mem:write_u8(i, f1:read("*line")) end	-- on screen timer
				for i=0x6a0c, 0x6a14, 4 do s1["item-"..tostring(i)] = tonumber(f1:read("*line")) end  -- bonus items
				for i=0x6400, 0x649f do mem:write_u8(i, f1:read("*line")) end	-- fires
				for i=0x6500, 0x65ff do mem:write_u8(i, f1:read("*line")) end	-- bouncers and pies
				for i=0x6700, 0x683f do mem:write_u8(i, f1:read("*line")) end	-- barrels (x10)
				for i=0x6280, 0x628f do mem:write_u8(i, f1:read("*line")) end	-- retractable ladders
				for i=0x62a0, 0x62a6 do mem:write_u8(i, f1:read("*line")) end	-- conveyors
				for i=0x6292, 0x6299 do s1["rivet-"..tostring(i)] = tonumber(f1:read("*line")) end   -- rivets
				if stage == 3 then
					for i=0x6600, 0x665f do mem:write_u8(i, f1:read("*line")) end	-- elevators (x6)
				end
				f1:flush()
				--------------------------------------------------------------------------------------------------------

				-- Sync: P2 also dies
				if s1["alive"] == 0 and olds1 and olds1["alive"] == 1 then mem:write_u8(0x6200, 0) end

				-- Slight speed ahead so P2 is waiting for P1
				if s2["mode"] > 6 and s2["mode"] < 12 then
					display_progress("Speed ahead")
					vid.throttle_rate = 1.15
				else
					vid.throttle_rate = 1
					if pa2 then pa2:write(performance_stats()) end
				end

				-- Wait for sync with P1 session
				if s2["mode"] == 12 and s1["mode"] < 12 then
					display_progress("Waiting for sync")
					snd.attenuation = -32
					emu.pause()
				else
					emu.unpause()
					snd.attenuation = att
				end

				-- mute music and non-gameplay sounds from session 2
				if s2["mode"] ~= 12 then snd.attenuation = -32 else snd.attenuation = att end

				-- Remove bonus items collected by P1
				if s1["mode"] == 12 and stage > 1 then
					for i=0x6a0c, 0x6a14, 4 do
						if s1["item-"..tostring(i)] == 0 then mem:write_u8(i, 0) end
					end
				end

				-- Check and remove P1 rivets
				if s1["mode"] == 12 and stage == 4 then sync_rivets(s1) end

				-- Sync: P2 also finishes
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
					emu.pause()  -- unpaused during sync at top
				end

				-- Store session 2 info --------------------------------------------------------------------------------
				f2:seek("set")  -- set cursor to start of file
				f2:write(s2["mode"].."\n")  -- mode
				f2:write(mem:read_u8(0x6200).."\n")  -- alive status
				f2:write(mem:read_u8(0x6203).."\n")  -- x pos
				f2:write(mem:read_u8(0x6205).."\n")  -- y pos
				f2:write(mem:read_u8(0x6010).."\n")  -- input state
				f2:write(mem:read_u8(0x694d).."\n")  -- sprite value
				f2:write(mem:read_u8(0x6217).."\n")  -- hammer active
				f2:write(mem:read_u8(0x6350).."\n")  -- enemy hit
				f2:write(mem:read_u8(0x6352).."\n")  -- enemy type
				f2:write(mem:read_u8(0x6354).."\n")  -- enemy no
				for i=0x76e1, 0x7781, 0x20 do f2:write(mem:read_u8(i).."\n") end	-- score
				for i=0x6a30, 0x6a34 do f2:write(mem:read_u8(i).."\n") end			-- points
				for i=0x6292,0x6299 do f2:write(mem:read_u8(i).."\n") end			-- rivets
				for i=0x6a0c, 0x6a14, 4 do f2:write(mem:read_u8(i).."\n") end		-- bonus items
				for i=0x6a18, 0x6a1f do f2:write(mem:read_u8(i).."\n") end 			-- hammer sprites
				for i=0x6a2c, 0x6a2f do f2:write(mem:read_u8(i).."\n") end  		-- smash sprites
				for i=0x6a30, 0x6a33 do f2:write(mem:read_u8(i).."\n") end  		-- score sprites
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

				-- Handle change of configuration.  Prompt user to exit.
				if manager.ui.menu_active then exitframe = frame end
				if not manager.ui.menu_active and exitframe > 0 and frame < exitframe + 300 then
					mac:popmessage("Please exit DKBros. to update your configuration")
				end

				s1["frame"] = frame
				s1["mode"] = mode
				s1["x"] = mem:read_u8(0x6203)
				s1["y"] = mem:read_u8(0x6205)
				s1["hammer_active"] = mem:read_u8(0x6217)

				-- Retrieve session 2 info --------------------------------------------------------------------------------
				f2:seek("set")  -- set cursor to start of file
				s2["mode"] = tonumber(f2:read("*line"))	          -- mode			
				s2["alive"] = tonumber(f2:read("*line"))          -- alive status
				s2["x"] = tonumber(f2:read("*line"))              -- x position
				s2["y"] = tonumber(f2:read("*line"))              -- y position
				s2["input_state"] = tonumber(f2:read("*line"))    -- input_state
				s2["sprite"] = tonumber(f2:read("*line"))         -- sprite value
				s2["hammer_active"] = tonumber(f2:read("*line"))  -- hammer active
				s2["enemy_hit"] = tonumber(f2:read("*line"))      -- enemy hit
				s2["enemy_type"] = tonumber(f2:read("*line"))     -- enemy type
				s2["enemy_no"] = tonumber(f2:read("*line"))       -- enemy no
				for i=0x7481, 0x7521, 0x20 do mem:write_u8(i, f2:read("*line")) end  -- score
				for i=0x6a30, 0x6a34 do s2["points-"..tostring(i)] = tonumber(f2:read("*line")) end  -- points				
				for i=0x6292, 0x6299 do s2["rivet-"..tostring(i)] = tonumber(f2:read("*line")) end   -- rivets
				for i=0x6a0c, 0x6a14, 4 do s2["item-"..tostring(i)] = tonumber(f2:read("*line")) end -- bonus items
				for i=0x6938, 0x693f do mem:write_u8(i, f2:read("*line")) end  	-- hammer sprites to alternate sprite address
				for i=0x6934, 0x6937 do mem:write_u8(i, f2:read("*line")) end  	-- smash sprites to alternate sprite address
				for i=0x6940, 0x6943 do mem:write_u8(i, f2:read("*line")) end  	-- score sprites to alternate sprite address
				-----------------------------------------------------------------------------------------------------------

				if status < 3 then display_title() end

				-- Sync: P1 also dies
				if s2["alive"] == 0 and olds2 and olds2["alive"] == 1 then mem:write_u8(0x6200, 0) end

				-- Wait for sync with P2 session.  This shouldn't really happen.
				if s1["mode"] == 12 and s2["mode"] < 12 then
					display_progress("Waiting for sync")
					snd.attenuation = -32
					vid.throttle_rate = 0.05
				else
					snd.attenuation = att
					vid.throttle_rate = 1
					if pa1 then pa1:write(performance_stats()) end
				end

				-- display arrows indicating that scores are combined
				if s1["mode"] and s1["mode"] > 0 then
					draw_sprite(0, 248, 60)
					draw_sprite(0, 248, 136, 4)
				end

				-- Flashing 2UP in time with 1UP
				if mem:read_u8(0x7740) ~= 0x10 then
					steer_sprite = 0x62
					write_message(0x74e0, "2UP")
				else
					write_message(0x74e0, "   ")
					steer_sprite = 0x64
				end

                -- Store lowest players Y position at 0x6102 for fire tracking and barrel logic mods
				if s1["mode"] == 12 then
					if s2["y"] > s1["y"] then mem:write_u8(0x6102, s2["y"]) else mem:write_u8(0x6102, s1["y"]) end
				end

				if stage == 1 and s1["mode"] >= 12 then
					-- Determine the active barrel steerer for barrel steering mod
                    if olds1 and olds1["hammer_active"] == 0 and s1["hammer_active"] == 1 then active_steerer = 1 end
                    if olds2 and olds2["hammer_active"] == 0 and s2["hammer_active"] == 1 then active_steerer = 2 end
                    -- Store the X, Y position of the active barrel steerer and input state
                    if active_steerer == 2 then
						mem:write_u8(0x6103, s2["x"])
                        mem:write_u8(0x6104, s2["input_state"])
                        for i=0x6980, 0x69a4, 4 do -- update barrel colour for P2 steering
							local _t = mem:read_u8(i+1)
							if _t % 128 >= 25 and _t % 128 <=27 then mem:write_u8(i+2, 10) else mem:write_u8(i+2, 7) end
                        end
						write_data(0x6a74, {220, steer_sprite, 7, 4})-- display P2 steering indicator
                    else
                        mem:write_u8(0x6103, s1["x"])
                        mem:write_u8(0x6104, mem:read_u8(0x6010))
						write_data(0x6a74, {68, steer_sprite, 11, 4})-- display P1 steering indicator
                    end
                end

				if stage == 1 and s1["mode"] < 12 then active_steerer = 1 end  -- set active steerer back to 1

				-- detect and reposition spawning fireballs on rivet stage
				if stage == 4 and s1["mode"] == 12 then
					local _spawn_addr = mem:read_u16(0x6107)
					if _spawn_addr >= 0x6400 and _spawn_addr <= 0x649f then
						-- logic to determine 3 safe spawn positions (from 8) and select one randomly.  Adjust for more Y distance.
						local _dt = {}  -- distance table
						for i=1, #spawn_table do
							local _x = math.min(math.abs(s1["x"] - spawn_table[i][1]), math.abs(s2["x"] - spawn_table[i][1]))
							local _y = math.min(math.abs(s1["y"] - spawn_table[i][2]), math.abs(s2["y"] - spawn_table[i][2])) * 0.9
							table.insert(_dt, {i, _x + _y})
						end
						table.sort(_dt, function(lhs, rhs) return lhs[2] < rhs[2] end)
						local _r = _dt[math.random(6, 8)][1]  -- pick randomly from the safest 3 positions
						mem:write_u8(_spawn_addr+0x3, spawn_table[_r][1])
						mem:write_u8(_spawn_addr+0x5, spawn_table[_r][2])
						mem:write_u8(_spawn_addr+0xe, spawn_table[_r][1])
						mem:write_u8(_spawn_addr+0xf, spawn_table[_r][2])
						mem:write_u16(0x6107, 0)  -- clear my spawning flag
					end
				end

				-- Remove bonus items collected by P2
				if s2["mode"] == 12 and stage > 1 then
					for i=0x6a0c, 0x6a14, 4 do
						if s2["item-"..tostring(i)] == 0 then mem:write_u8(i, 0) end  -- remove bonus items
					end
				end

				-- Take unused sprite from session 1 for player 2 Jumpman.
				if s1["mode"] > 11 and s1["mode"] < 16 then
					mem:write_u8(0x6a70, s2["x"])
					mem:write_u8(0x6a71, s2["sprite"])
					mem:write_u8(0x6a72, 12)  -- Set Jumpman colour to blue
					mem:write_u8(0x6a73, s2["y"])
				end

				-- Update fire sprite colour when P2 is smashing.
				if s1["mode"] == 12 and s2["mode"] == 12 and s2["hammer_active"] == 1 then
					for i=0x69d0, 0x69ef, 0x04 do mem:write_u8(i+2, 0) end
				end

				-- clear any smash sprite remnants
				if s2["enemy_hit"] == 0 and olds2 and olds2["enemy_hit"] == 1 then mem:write_u8(0x6a2d, 0x64) end

				-- Adjust score sprite colour for P2
				if s1["mode"] == 12 then mem:write_u8(0x6942, 9) end

				-- Adjust hammer sprite colour for P2 and only display when session 1 is ready
				if s1["mode"] >= 11 then
					mem:write_u8(0x693a, mem:read_u8(0x693a) + 4)
					mem:write_u8(0x693e, mem:read_u8(0x693e) + 4)
				else
					mem:write_u8(0x6939, 0x64)
					mem:write_u8(0x693d, 0x64)
				end

				-- Cleanup previously removed fires and pies
				if cleanup and s2["enemy_hit"] ~= 1 then
					mem:write_u8(cleanup, 0)
						mem:write_u8(offset + 0x03, 0)
						mem:write_u8(offset + 0x05, 0)
						mem:write_u8(offset + 0x0e, 0)
						mem:write_u8(offset + 0x0f, 0)
					cleanup = nil
				end

				-- Remove enemies hit by P2 hammer
				if s2["enemy_hit"] == 1 then
					address, size = s2["enemy_type"] * 0x100, 0x20
					if s2["enemy_type"] == 0x65 then address, size = 0x65a0, 0x10 end
					offset = address + (s2["enemy_no"] * size)
					if olds2["enemy_hit"] == 0 then
						s2["enemy_x"] = mem:read_u8(offset + 0x03) - 16
						s2["enemy_y"] = mem:read_u8(offset + 0x05)
						-- clear the sprite
						if s2["enemy_type"] == 0x64 then  -- fires
							mem:write_u8(0x69d0 + (s2["enemy_no"] * 4) + 1, 0x64)
						elseif s2["enemy_type"] == 0x67 then  -- barrels
							mem:write_u8(0x6980 + (s2["enemy_no"] * 4) + 1, 0x64)
						elseif s2["enemy_type"] == 0x65 then  -- pies
							mem:write_u8(0x69b8 + (s2["enemy_no"] * 4) + 1, 0x64)
						end
					end

					-- remove the enemy from the screen and flag for later cleanup
					mem:write_u8(offset + 0x03, 0)
					mem:write_u8(offset + 0x05, 0)
					if s2["enemy_type"] == 0x64 or s2["enemy_type"] == 0x65 then  -- fires and pies
						mem:write_u8(offset + 0x03, 250)
						mem:write_u8(offset + 0x05, 8)
						mem:write_u8(offset + 0x0e, 250)
						mem:write_u8(offset + 0x0f, 8)
						cleanup = offset
					end
				end

				-- Check and remove P2 rivets
				if s2["mode"] == 12 and stage == 4 then sync_rivets(s2) end

				-- Sync: P1 also finishes
				if s1["mode"] == 12 and s2["mode"] == 0x16 then
					mem:write_u8(0x638c, 0)  -- don't award bonus points,  P2 gets the bonus
					mem:write_u8(0x62b1, 0)  -- don't award bonus points,  P2 gets the bonus
					if stage < 4 then
						mem:write_u8(0x6205, 0x30)
					else
						mem:write_u8(0x6290, 0)
						sync_rivets(s2, true)	-- cleanup rivets after stage completion
					end
				end
				if stage == 4 and s1["mode"] == 22 then
					-- Move P1 to top
					mem:write_u8(0x694c, 66)  -- x
					mem:write_u8(0x694d, 128) -- right facing
					mem:write_u8(0x694f, 80)  -- y
					-- Move P2 to top
					mem:write_u8(0x6a70, 188) -- x
					mem:write_u8(0x6a71, 0)   -- left facing
					mem:write_u8(0x6a73, 80)  -- y
				end

				-- Force delay when player 2 is smashing an enemy
				if s1["mode"] == 12 then
					if s2["enemy_hit"] == 1 then
						mem:write_u8(0x6350, 1)  -- surprised this actually worked!
						mem:write_u8(0x6345, 1)  --"--
						snd.attenuation = -32
					else
						snd.attenuation = att
						if olds2 and olds2["enemy_hit"] == 1 then
							mem:write_u8(0x6350, 0)
							mem:write_u8(0x6345, 0)
						end
					end
				end

				-- Display combined score inplace of high score
				if s1["mode"] > 0 then
					combined = string.format("%07d", tonumber(read_score(0x7781, 6)) + tonumber(read_score(0x7521, 6)))
					if #combined == 7 then
						write_message(0x7661, combined, 0x70)
					end
				end

				-- Store session 1 info --------------------------------------------------------------------------------
				f1:seek("set")  -- set cursor to start of file
				f1:write(s1["mode"].."\n")           -- mode
				f1:write(mem:read_u8(0x62b1).."\n")  -- bonus timer
				f1:write(mem:read_u8(0x6200).."\n")  -- alive status
				f1:write(mem:read_u8(0x6203).."\n")  -- x position
				f1:write(mem:read_u8(0x6205).."\n")  -- y position
				f1:write(mem:read_u8(0x6350).."\n")  -- enemy hit a
				for i=0x74e6, 0x7486, -0x20 do f1:write(mem:read_u8(i).."\n") end	-- on screen timer
				for i=0x6a0c, 0x6a14, 4 do f1:write(mem:read_u8(i).."\n") end		-- bonus items
				for i=0x6400, 0x649f do f1:write(mem:read_u8(i).."\n") end			-- fires
				for i=0x6500, 0x65ff do f1:write(mem:read_u8(i).."\n") end			-- bouncers and pies
				for i=0x6700, 0x683f do f1:write(mem:read_u8(i).."\n") end			-- barrels (x10)
				for i=0x6280, 0x628f do f1:write(mem:read_u8(i).."\n") end			-- retractable ladders
				for i=0x62a0, 0x62a6 do f1:write(mem:read_u8(i).."\n") end			-- conveyors
				for i=0x6292, 0x6299 do f1:write(mem:read_u8(i).."\n") end  		-- rivets
				if stage == 3 then
					for i=0x6600, 0x665f do f1:write(mem:read_u8(i).."\n") end		-- elevators (x6)
				end
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
		if frame % 12 == 0 then
			local i = ({0, 1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2, 1})[math.floor((frame / 12) % 16) + 1]
			write_message(0x77ad + i, "                            ")
			write_message(0x77ae + i, " ++  + +  +++ +++ +++ +++   ")
			write_message(0x77af + i, " + + + +  + + + + + + +     ")
			write_message(0x77b0 + i, " + + ++   ++  ++  + + +++   ")
			write_message(0x77b1 + i, " + + + +  + + + + + +   +   ")
			write_message(0x77b2 + i, " ++  + +  +++ + + +++ +++ + ")
			write_message(0x77b3 + i, "                            ")
			if frame % 192 < 96 then write_message(0x77bf, " PROTOTYPE I") else write_message(0x77bf, " BY 10YARD  ") end
			if invincible == 1 then write_message(0x7683, "INVINCIBLE") end  -- Invincible mode
		end
	end

	function display_progress(message)
		scr:draw_box(0, 0, 72, 14, 0x77777777)
		scr:draw_text(3, 3, message.."...", 0xffffffff)
	end

	function sync_rivets(session_data, cleanup_only)
		-- synchronise rivets with data from the other session (s1 or s2)
		local _cleanup_only = cleanup_only or false
		for i=0x6292, 0x6299 do
			if not _cleanup_only then
				if mem:read_u8(i) == 1 then
					-- Has the other player pulled this rivet?
					if session_data["rivet-"..tostring(i)] == 0 then
						mem:write_u8(i, 0)								-- flag rivet as removed
						mem:write_u8(rivet_pos[i - 0x6291] - 1, 0x10)	-- remove rivet from screen (top part)
						mem:write_u8(rivet_pos[i - 0x6291], 0x10)		-- remove rivet from screen (bottom part)
						mem:write_u8(0x6290, mem:read_u8(0x6290) - 1)	-- update rivet count
					end
				end
			else
				-- Cleanup rivet remnants on screen after stage completion
				if session_data["rivet-"..tostring(i)] == 0 then
					mem:write_u8(rivet_pos[i - 0x6291] - 1, 0x10)	-- remove rivet from screen (top part)
					mem:write_u8(rivet_pos[i - 0x6291], 0x10)		-- remove rivet from screen (bottom part)
				end
			end
		end
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
	
	function draw_sprite(id, y, x, flip)
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
				mem:write_u8(start_addr - ((key - 1) * 32), ({0x4d, 0x4e, 0x4f})[(start_addr % 3) + 1])
			end
		end
	end	
	
	function write_rom_message(start_addr, text)
		-- write characters of message to ROM
		for key=1, string.len(text) do
			mem:write_direct_u8(start_addr + (key - 1), string.find(characters, string.sub(text, key, key)) - 1)
		end
	end

	function performance_stats()
		-- Return performance stats as CSV
		-- frame, stage, mode, expected speed, actual speed, difference
		if mode == 12 then
			return tostring(frame)..","..tostring(stage)..","..tostring(mode)..","..
					tostring(string.format("%.3f", vid.throttle_rate * 100))..","..
					tostring(string.format("%.3f", vid.speed_percent * 100))..","..
					tostring(string.format("%.3f", (vid.throttle_rate - vid.speed_percent) * 100)).."\n"
		end
	end

	emu.add_machine_reset_notifier(function()	
		initialize()
	end)

	emu.add_machine_stop_notifier(function()
		f1:close()
		f2:close()
		if pa1 then	pa1:close() end
		if pa2 then	pa2:close() end
    end)
	
	emu.register_frame_done(main, "frame")
end
return exports