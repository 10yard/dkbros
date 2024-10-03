

    oooooo  o    o    oooooo                           
    o     o o   o     o     o ooooo   oooo   oooo      
    o     o o  o      o     o o    o o    o o          
    o     o ooo       oooooo  o    o o    o  oooo      
    o     o o  o      o     o ooooo  o    o      o ooo 
    o     o o   o     o     o o   o  o    o o    o ooo 
    oooooo  o    o    oooooo  o    o  oooo   oooo  ooo

PROTOTYPE by Jon Wilson (10yard)

The arcade version of Donkey Kong adapted for 2 player co-operative gameplay.

DKBros. includes a program wrapper and a LUA plugin for MAME.    

How to Play
-----------
Extract the contents of the dkbros_prototype zip file.  It includes everything you need apart from the `dkong.zip` rom file.

Place your `dkong.zip` into the wolf256\roms folder.

Run the `dkbros.exe` program.  This will set up a 2 player co-op Donkey Kong session in MAME.  

Press the start button to play or see below for notes on configuring the controls.


Features
--------

- 2 players are controlled independently in the same game.

- Each player gets their own hammers, and they can be smashed together

- Player 1 gets the barrel control.  

- Pulling rivets is fun with 2 players sharing the task, and it reduces some of the difficulty.

- If one player completes the stage then both players complete the stage together but the player 
    completing the stage gets the bonus points - unless you finish exactly at the same time.

- Both players accrue points independently but there is a combined score displayed in the centre.

- If one player dies then both players die.

- There are 7 lives shared between both players.


Default Controls
----------------
The default player controls are mapped to one keyboard as follows.

### Player 1
- P1 Up    = W
- P1 Down  = S
- P1 Left  = A
- P1 Right = D
- P1 Jump  = Left Ctrl

### Player 2
- P2 Up    = Up Arrow
- P2 Down  = Down Arrow
- P2 Left  = Left Arrow
- P2 Right = Right Arrow
- P2 Jump  = Space

Controls can be customised as per regular MAME including using joysticks.


Steps to Configure Controls
---------------------------
1. Run dkbros.exe and press the TAB key to open the settings menu
2. Select "Input Settings"
3. Select "Input Assignments (this system)"
4. Change 1P and 2P input controls as required
5. Close the settings menu
6. Exit and restart dkbros game to apply changes for both players

**IMPORTANT:**  Please be sure to map every input for P1 and P2.


Parameters
----------
You can launch the game in windowed mode by providing the parameter "WINDOW"
i.e. dkbros WINDOW

To assist testing there is an invincible mode.
i.e. dkbros INVINCIBLE


Thanks to
---------
The Donkey Kong rom hacking resource - https://github.com/furrykef/dkdasm

The MAMEdev team - https://docs.mamedev.org/

WolfMAME by Mahlemiut - https://github.com/mahlemiut/wolfmame

Mr2Nut123 for his ideas and assistance with testing - https://www.twitch.tv/mr2nut123

Paul Goes for his assistance with testing - https://donkeykonghacks.net/


Feedback
--------
Please send feedback to jon123wilson@hotmail.com