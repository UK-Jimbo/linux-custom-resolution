Set Resolution Utility for Zorin OS / GNOME Screen Sharing
Overview

This utility configures a custom display resolution (default: 2560×1440 at 60 Hz) and ensures it is automatically applied at login — including during remote sessions via GNOME Screen Sharing.

It consists of two scripts:

set-resolution.sh — the main configuration and setup script.

set-resolution-startup.sh — an automatically generated startup helper invoked on login to reapply the resolution.

The setup is idempotent — running the script multiple times will simply refresh and correct any prior configuration.

Features

Automatically detects the active display (e.g. Virtual-1).

Safely creates and applies the 2560×1440_60.00 mode using xrandr.

Configures a persistent autostart entry via ~/.config/autostart.

Handles GNOME screen sharing sessions, including delayed display availability.

Waits up to 20 seconds for the display to initialise before applying the mode.

Fully repeatable and safe to re-run.

Usage

Make the script executable:

chmod +x set-resolution.sh


Run the script:

./set-resolution.sh


The script will:

Detect the active display.

Create and apply the new resolution.

Prompt you to configure autostart (recommended).

When prompted for autostart:

Enter y to enable automatic resolution application at login.

This creates:

~/.local/bin/set-resolution-startup.sh

~/.config/autostart/set-resolution.desktop

Verification:

After reboot or logout/login, the display should automatically switch to 2560×1440.

If using screen sharing, the script will apply the resolution shortly after the remote session becomes active.

Running Multiple Times

You can safely re-run set-resolution.sh at any time.
Each run will:

Remove any previous resolution definitions.

Recreate the correct mode and reapply it.

Refresh the autostart configuration.

No manual cleanup is required.

Troubleshooting

Black screen after login:

The new script version introduces a delay before applying the resolution to prevent black screens caused by premature mode setting.

If you had an older version, re-run the new script to overwrite previous configuration.

No display detected:

Ensure you are running in an X11 session (not Wayland).

You can check with:

echo $XDG_SESSION_TYPE


If the result is wayland, log out and choose “Zorin on Xorg” at the login screen.

Autostart not triggering:

Verify that the file exists and is enabled:

cat ~/.config/autostart/set-resolution.desktop


If missing or invalid, re-run ./set-resolution.sh and answer y when prompted.

Removal

To remove the autostart behaviour:

rm -f ~/.config/autostart/set-resolution.desktop
rm -f ~/.local/bin/set-resolution-startup.sh

Notes

The script uses xrandr commands compatible with GNOME under Zorin OS.

The display name (e.g. Virtual-1, VGA-1, HDMI-1) is automatically detected and does not need to be edited manually.

The script can be adapted to different resolutions by editing the WIDTH, HEIGHT, and REFRESH values near the top of set-resolution.sh.
