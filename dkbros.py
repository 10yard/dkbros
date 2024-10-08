"""
******* *    *    ******
*     * *   *     *     * *****   ****   ****
*     * *  *      *     * *    * *    * *
*     * ***       ******  *    * *    *  ****
*     * *  *      *     * *****  *    *      * ***
*     * *   *     *     * *   *  *    * *    * ***
******  *    *    ******  *    *  ****   ****  ***
2 Player co-op Donkey Kong.
Prototype F by 10yard

A wrapper for MAME to simplify launch of the DKBros. plugin and
to synchronise realtime data across 2 sessions. Session 2 is
hidden from view.
"""
import os
import sys
import threading
import subprocess
import ctypes

MAME_COMMAND = 'dkmame dkong -plugin coopkong -keyboardprovider rawinput -background_input -volume 0 -skip_gameinfo -throttle -nosleep -autoframeskip'
DEFAULT_VIDEO = '-video bgfx -bgfx_screen_chains unfiltered'
UPDATE_LIST = [(":IN0", ":INX"), ("P1_", "PX_"), (":IN1", ":IN0"), ("P2_", "P1_"), (":INX", ":IN1"), ("PX_", "P2_")]

def background_mame(session_specific_args):
    subprocess.Popen(f"{MAME_COMMAND} {session_specific_args}", creationflags=subprocess.CREATE_NO_WINDOW)

def cleanup_mame():
    subprocess.run(f"taskkill /f /IM dkmame.exe", creationflags=subprocess.CREATE_NO_WINDOW)

if __name__ == "__main__":
    cleanup_mame()

    # Are there optional parameters i.e. "WINDOW", "INVINCIBLE", "SHOW2" or "INVINCIBLE SHOW2"
    optional_parameters = ""
    if len(sys.argv) > 1:
        optional_parameters = sys.argv[1].upper().strip()

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
            session2_args = session2_args.replace("-cfg_directory config\dkong_p2", f"-cfg_directory config\dkong_p1")

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

        if optional_parameters and not window:
            subprocess.run(f"{MAME_COMMAND} {session1_args}")
        else:
            subprocess.run(f"{MAME_COMMAND} {session1_args}", creationflags=subprocess.CREATE_NO_WINDOW)

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
