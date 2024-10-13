![DK Bros. Marquee](https://i.imgur.com/RQsTYYQ.png)

The arcade version of Donkey Kong adapted for 2 player co-operative gameplay.

DKBros. includes a program wrapper and a LUA plugin with MAME v0.256 all bundled in a convenient ready to play package.    

Development by Jon Wilson (10yard)


## How to Play

- Extract the contents of the dkbros_prototype zip file into a folder.  It includes everything you need apart from the `dkong.zip` rom file.

- Place your `dkong.zip` into the wolf256\roms folder.

- Run the `dkbros.exe` program.  This will set up a 2 player co-op Donkey Kong session in MAME.  

- Press the start button to play 

Refer to notes below for configuring the controls.


## Features

- 2 players are controlled independently in the same game.

- Each player gets their own hammers, and they can be smashed together

- The last player to grab a hammer gets the barrel control and retains control until the other player grabs a hammer.  The barrels change colour when P2 has the steering. 

- Pulling rivets is fun with 2 players sharing the task.  The fireballs spawn in a calculated safe position for both players.

- If one player completes the stage then both players complete the stage together but the player completing the stage gets the bonus points - unless you finish exactly at the same time.

- Both players accrue points independently but there is a combined score displayed in the centre.

- If one player dies then both players die.

- There are 7 lives shared between both players.


## Default Controls
The default player controls are mapped to one keyboard as follows.

#### Player 1
- P1 Up    = W
- P1 Down  = S
- P1 Left  = A
- P1 Right = D
- P1 Jump  = Left Ctrl

#### Player 2
- P2 Up    = Up Arrow
- P2 Down  = Down Arrow
- P2 Left  = Left Arrow
- P2 Right = Right Arrow
- P2 Jump  = Space

Controls can be customised as per regular MAME including using joysticks.


## Steps to Configure Controls

- Run dkbros.exe and press the TAB key to open the settings menu 
- Select "Input Settings"
- Select "Input Assignments (this system)"
- Change 1P and 2P input controls as required 
- Close the settings menu 
- Exit and restart dkbros game to apply changes for both players

Please be sure to map every input for P1 and P2.


## Parameters

You can launch the game in windowed mode by providing the parameter "WINDOW"
i.e. `dkbros WINDOW`

To assist testing there is an invincible mode.
i.e. `dkbros INVINCIBLE`


## Thanks to

The Donkey Kong rom hacking resource - https://github.com/furrykef/dkdasm

Mr2Nut123 for his ideas, assistance with testing and marquee design - https://www.twitch.tv/mr2nut123

Paul Goes for his thorough testing - https://donkeykonghacks.net/

The MAMEdev team - https://docs.mamedev.org/

WolfMAME by Mahlemiut - https://github.com/mahlemiut/wolfmame


## Feedback

Please send feedback to jon123wilson@hotmail.com