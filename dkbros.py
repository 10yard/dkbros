"""
******* *    *    ******
*     * *   *     *     * *****   ****   ****
*     * *  *      *     * *    * *    * *
*     * ***       ******  *    * *    *  ****
*     * *  *      *     * *****  *    *      * ***
*     * *   *     *     * *   *  *    * *    * ***
******  *    *    ******  *    *  ****   ****  ***
2 Player co-op Donkey Kong
Prototype by 10yard
"""
import os
import sys
import threading
import subprocess
import time
import shutil

# Are there optional parameters i.e. "WINDOW", "INVINCIBLE", "SHOW2" or "INVINCIBLE SHOW2"
optional_parameters = ""
if len(sys.argv) > 1:
    optional_parameters = sys.argv[1].upper()

# Windowed mode possible by providing "WINDOW" parameter or by creating a file named WINDOW or WINDOW.txt
window = ""
if "WINDOW" in optional_parameters or os.path.exists("WINDOW.txt") or os.path.exists("WINDOW"):
    window = " -window"

MAME_COMMAND = 'mame dkong -plugin coopkong -background_input -volume 0 -skip_gameinfo -prescale 8'
session1_args = f'-autoboot_command "--S1 {optional_parameters}" -cfg_directory config\dkong_p1 -video bgfx {window}'
session2_args = f'-autoboot_command "--S2 {optional_parameters}" -cfg_directory config\dkong_p2 -video none -window -seconds_to_run -1'

def background_mame(session_specific_args):
    subprocess.Popen(f"{MAME_COMMAND} {session_specific_args}", creationflags=subprocess.CREATE_NO_WINDOW)

if __name__ == "__main__":
    os.chdir("wolf256")

    # Create empty files for data exchange between sessions
    open("session/s1.dat", mode='a').close()
    open("session/s2.dat", mode='a').close()

    # creating thread for MAME session 2.  This ends when the main process ends (with session 2).
    if "SHOW2" in optional_parameters:
        session1_args += " -window"
        session2_args = session2_args.replace("-video none", f"-video bgfx")
        background_mame(session2_args)
    else:
        t1 = threading.Thread(target=background_mame, args=(session2_args,) )
        t1.daemon = True
        t1.start()

    if optional_parameters:
        subprocess.run(f"{MAME_COMMAND} {session1_args}")
    else:
        subprocess.run(f"{MAME_COMMAND} {session1_args}", creationflags=subprocess.CREATE_NO_WINDOW)

    # Update the P2 controller configuration file
    check = "P1_JOYSTICK_LEFT", "P1_JOYSTICK_RIGHT", "P1_JOYSTICK_UP", "P1_JOYSTICK_DOWN", "P1_BUTTON1", "P2_JOYSTICK_LEFT", "P2_JOYSTICK_RIGHT", "P2_JOYSTICK_UP", "P2_JOYSTICK_DOWN", "P2_BUTTON1"
    valid = True
    with open("config\dkong_p1\dkong.cfg") as r:
        text = r.read()
        for key in check:
            if not key in text:
                valid = False
                break
        if not valid:
            # Restore default controller file
            shutil.copy("config\default_dkong.cfg", "config\dkong_p1\dkong.cfg")
        text = text.replace(":IN0", ":INX")
        text = text.replace("P1_", "PX_")
        text = text.replace(":IN1", ":IN0")
        text = text.replace("P2_", "P1_")
        text = text.replace(":INX", ":IN1")
        text = text.replace("PX_", "P2_")
    with open("config\dkong_p2\dkong.cfg", "w") as w:
        w.write(text)