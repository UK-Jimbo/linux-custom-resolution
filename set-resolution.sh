#!/bin/bash

# Desired resolution
MODE_NAME="2560x1440_60.00"
WIDTH=2560
HEIGHT=1440
REFRESH=60

# Check if running X11
if [ "$XDG_SESSION_TYPE" != "x11" ]; then
    echo "Error: This script requires an X11 session. Current session: $XDG_SESSION_TYPE"
    exit 1
fi

# Check connected display
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}')
if [ -z "$DISPLAY_NAME" ]; then
    echo "Error: No connected display found."
    exit 1
fi

# Check if mode already exists
if xrandr | grep -q "$MODE_NAME"; then
    echo "Mode $MODE_NAME already exists. Adding to $DISPLAY_NAME..."
else
    # Generate modeline
    MODEL=$(cvt $WIDTH $HEIGHT $REFRESH | grep Modeline | cut -d' ' -f2-)
    echo "Creating new mode: $MODE_NAME"
    xrandr --newmode $MODEL
fi

# Add mode to display
xrandr --addmode $DISPLAY_NAME $MODE_NAME

# Switch to the new mode
xrandr --output $DISPLAY_NAME --mode $MODE_NAME

echo "Resolution set to $MODE_NAME on $DISPLAY_NAME"

# Prompt user to configure autostart
read -p "Do you want to add this resolution to autostart? (y/n): " AUTOSTART_CHOICE
if [[ "$AUTOSTART_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p ~/.config/autostart
    AUTOSTART_FILE="$HOME/.config/autostart/set-resolution.desktop"

    cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Exec=bash -c "xrandr --newmode '$MODE_NAME' $(cvt $WIDTH $HEIGHT $REFRESH | grep Modeline | cut -d' ' -f2-) ; xrandr --addmode $DISPLAY_NAME '$MODE_NAME' ; xrandr --output $DISPLAY_NAME --mode '$MODE_NAME'"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set custom $MODE_NAME resolution
Comment=Apply custom resolution on login
EOF

    chmod +x "$AUTOSTART_FILE"
    echo "Autostart configured. The resolution will be applied automatically on login."
else
    echo "Autostart not configured."
fi
