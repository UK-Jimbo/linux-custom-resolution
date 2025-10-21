#!/bin/bash

MODE_NAME="2560x1440_60.00"
WIDTH=2560
HEIGHT=1440
REFRESH=60

# Ensure running X11
if [ "$XDG_SESSION_TYPE" != "x11" ]; then
    echo "Error: You must be running an X11 session."
    exit 1
fi

# Detect active display
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}')
if [ -z "$DISPLAY_NAME" ]; then
    echo "Error: No connected display found."
    exit 1
fi
echo "Active display detected: $DISPLAY_NAME"

# Generate modeline
MODEL_LINE=$(cvt $WIDTH $HEIGHT $REFRESH | grep Modeline)
MODEL_NAME_LINE=$(echo $MODEL_LINE | awk '{print $2}')
MODEL_PARAMS=$(echo $MODEL_LINE | cut -d' ' -f3-)

# Remove previous mode if it exists (ignore errors)
xrandr --delmode $DISPLAY_NAME "$MODEL_NAME_LINE" 2>/dev/null
xrandr --rmmode "$MODEL_NAME_LINE" 2>/dev/null

# Try to create new mode, ignore BadName errors
xrandr --newmode "$MODEL_NAME_LINE" $MODEL_PARAMS 2>/dev/null || true
echo "Mode setup attempted: $MODEL_NAME_LINE"

# Add mode and apply (errors will generally not happen here)
xrandr --addmode $DISPLAY_NAME "$MODEL_NAME_LINE" 2>/dev/null || true
xrandr --output $DISPLAY_NAME --mode "$MODEL_NAME_LINE"
echo "Resolution set to $MODEL_NAME_LINE on $DISPLAY_NAME"

# Optional autostart
read -p "Do you want to add this resolution to autostart? (y/n): " AUTOSTART_CHOICE
if [[ "$AUTOSTART_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p ~/.config/autostart
    AUTOSTART_FILE="$HOME/.config/autostart/set-resolution.desktop"

    cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Exec=bash -c "xrandr --newmode \"$MODEL_NAME_LINE\" $(cvt $WIDTH $HEIGHT $REFRESH | grep Modeline | cut -d' ' -f3-) ; xrandr --addmode $DISPLAY_NAME \"$MODEL_NAME_LINE\" ; xrandr --output $DISPLAY_NAME --mode \"$MODEL_NAME_LINE\""
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set custom $MODEL_NAME_LINE resolution
Comment=Apply custom resolution on login
EOF

    chmod +x "$AUTOSTART_FILE"
    echo "Autostart configured. The resolution will be applied automatically on login."
else
    echo "Autostart not configured."
fi
