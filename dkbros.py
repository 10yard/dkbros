"""
OOOOOO   O    O    OOOOOO
O     O  O   O     O     O  OOOOO    OOOO    OOOO
O     O  O  O      O     O  O    O  O    O  O
O     O  OOO       OOOOOO   O    O  O    O   OOOO
O     O  O  O      O     O  OOOOO   O    O       O  OO
OOOOOO   O    O    OOOOOO   O    O   OOOO    OOOO   OO

2 Player co-op Donkey Kong
Version 1.0 by 10yard

A wrapper for MAME to simplify launch of the DKBros plugin and to synchronise realtime data across 2 sessions.
Session 2 is hidden from view.
"""
import os
import sys
import threading
import subprocess
import ctypes
import shutil

# Are there optional parameters e.g. "WINDOW", "INVINCIBLE", "SHOW2" or "INVINCIBLE WINDOW"
optional_parameters = ""
if len(sys.argv) > 1:
    optional_parameters = sys.argv[1].upper().strip()

DOUBLE = "2" if "DOUBLE" in optional_parameters or os.path.exists("DOUBLE.txt") else ""
MAME_COMMAND = f'dkmame{DOUBLE} dkong -plugin coopkong -keyboardprovider rawinput -background_input -volume 0 -skip_gameinfo -throttle -nosleep -autoframeskip'
DEFAULT_VIDEO = '-video bgfx -bgfx_screen_chains unfiltered'
UPDATE_LIST = [(":IN0", ":INX"), ("P1_", "PX_"), (":IN1", ":IN0"), ("P2_", "P1_"), (":INX", ":IN1"), ("PX_", "P2_")]

def background_mame(session_specific_args):
    subprocess.Popen(f"{MAME_COMMAND} {session_specific_args}", creationflags=subprocess.CREATE_NO_WINDOW)

def cleanup_mame():
    subprocess.run(f"taskkill /f /IM dkmame{DOUBLE}.exe", creationflags=subprocess.CREATE_NO_WINDOW)

if __name__ == "__main__":
    cleanup_mame()

    #Additional instance of DKBros for total of 4 players (2x2)
    if DOUBLE:
        if not os.path.exists("wolf256/dkmame2.exe"):
            shutil.copyfile("wolf256/dkmame.exe", "wolf256/dkmame2.exe")

    # Windowed mode possible by providing "WINDOW" parameter or by creating a file named WINDOW or WINDOW.txt
    window = ""
    if "WINDOW" in optional_parameters or os.path.exists("WINDOW.txt") or os.path.exists("WINDOW"):
        window = " -window"

    # autoboot command is craftily used to pass optional parameters to the plugin
    session1_args = f'-autoboot_command "--S1 {optional_parameters}" -cfg_directory config/dkong_p1 {DEFAULT_VIDEO} {window}'
    session2_args = f'-autoboot_command "--S2 {optional_parameters}" -cfg_directory config/dkong_p2 -video none -seconds_to_run -1'

    os.chdir("wolf256")
    if os.path.exists("roms/dkong.zip"):
        # Create empty files for data exchange between sessions
        open("session/s1.dat", mode='a').close()
        open("session/s2.dat", mode='a').close()

        if "DEBUG" in optional_parameters:
            session1_args += " -debug -window"

        if "SYNCINPUT" in optional_parameters:
            session2_args = session2_args.replace("-cfg_directory config/dkong_p2", f"-cfg_directory config/dkong_p1")

        if "SHOW2" in optional_parameters:
            session1_args += " -window"
            session2_args = session2_args.replace("-video none", f"-window {DEFAULT_VIDEO}")
            if "CONSOLE" in optional_parameters:
                subprocess.Popen(f"{MAME_COMMAND} {session2_args}")
            else:
                background_mame(session2_args)
        else:
            # create thread for session 2.  This ends with the main process.
            t2 = threading.Thread(target=background_mame, args=(session2_args,) )
            t2.daemon = True
            t2.start()

        # Issues with keyboard blocking when CREATE_NO_WINDOW used with fullscreen.  Removed code block for now.
        # if optional_parameters and not window:
        #     subprocess.run(f"{MAME_COMMAND} {session1_args}")
        # else:
        #     subprocess.run(f"{MAME_COMMAND} {session1_args}", creationflags=subprocess.CREATE_NO_WINDOW)

        subprocess.run(f"{MAME_COMMAND} {session1_args}")

        # Generate P2 controller configuration file
        # Take P2 controls from session 1 and apply them to P1 of session 2
        control_entries = "P1_JOYSTICK_LEFT", "P1_JOYSTICK_RIGHT", "P1_JOYSTICK_UP", "P1_JOYSTICK_DOWN", "P1_BUTTON1"
        valid = True
        with open("config\dkong_p1\dkong.cfg") as r:
            text = r.read()
            for key in control_entries:
                if not key in text:
                    valid = False
                    break
            if valid:
                for u in UPDATE_LIST:
                    text = text.replace(u[0], u[1])
                with open("config\dkong_p2\dkong.cfg", "w") as w:
                    w.write(text)
        cleanup_mame()
    else:
        ctypes.windll.user32.MessageBoxW(0, "You must place your dkong.zip file into the wolf256\\roms folder.", "Missing dkong.zip", 0)
