#!/bin/bash
#
# set-resolution.sh — Configure 2560x1440 resolution and persistent autostart
# Works with GNOME-based desktops (e.g. Zorin OS) including Screen Sharing sessions.
#

# ============================================
# CONFIGURATION VARIABLES
# ============================================
ASK_AUTOSTART=YES  # Set to NO to skip autostart prompt, YES to auto-enable, or ASK to prompt

MODE_NAME="2560x1440_60.00"
WIDTH=2560
HEIGHT=1440
REFRESH=60
AUTOSTART_FILE="$HOME/.config/autostart/set-resolution.desktop"
STARTUP_SCRIPT="$HOME/.local/bin/set-resolution-startup.sh"

# Ensure X11 is being used
if [ "$XDG_SESSION_TYPE" != "x11" ]; then
    echo "Error: This script requires an X11 session (not Wayland)."
    exit 1
fi

echo "Detecting active display..."
DISPLAY_NAME=$(xrandr | grep " connected" | awk '{print $1}')

if [ -z "$DISPLAY_NAME" ]; then
    echo "Error: No connected display detected."
    exit 1
fi

echo "Active display detected: $DISPLAY_NAME"

# Generate modeline
MODEL_LINE=$(cvt $WIDTH $HEIGHT $REFRESH | grep Modeline)
MODEL_NAME_LINE=$(echo "$MODEL_LINE" | awk '{print $2}')
MODEL_PARAMS=$(echo "$MODEL_LINE" | cut -d' ' -f3-)

# Remove old mode if present (ignore errors)
xrandr --delmode "$DISPLAY_NAME" "$MODEL_NAME_LINE" 2>/dev/null
xrandr --rmmode "$MODEL_NAME_LINE" 2>/dev/null

# Try to create new mode (ignore BadName errors)
xrandr --newmode "$MODEL_NAME_LINE" $MODEL_PARAMS 2>/dev/null || true

echo "Mode setup attempted: $MODEL_NAME_LINE"

# Add and apply the mode
xrandr --addmode "$DISPLAY_NAME" "$MODEL_NAME_LINE" 2>/dev/null || true
xrandr --output "$DISPLAY_NAME" --mode "$MODEL_NAME_LINE"

echo "Resolution set to $MODEL_NAME_LINE on $DISPLAY_NAME"
echo

# Determine autostart behavior based on ASK_AUTOSTART variable
AUTOSTART_CHOICE=""

case "${ASK_AUTOSTART^^}" in
    NO)
        echo "Autostart configuration skipped (ASK_AUTOSTART=NO)."
        AUTOSTART_CHOICE="n"
        ;;
    YES)
        echo "Configuring autostart (ASK_AUTOSTART=YES)..."
        AUTOSTART_CHOICE="y"
        ;;
    ASK|*)
        read -p "Do you want to configure this resolution to apply automatically on login? (y/n): " AUTOSTART_CHOICE
        ;;
esac

if [[ "$AUTOSTART_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Setting up autostart..."
    
    # Ensure directories exist
    mkdir -p "$(dirname "$AUTOSTART_FILE")"
    mkdir -p "$(dirname "$STARTUP_SCRIPT")"
    
    # Create startup script
    cat <<EOF > "$STARTUP_SCRIPT"
#!/bin/bash
MODE_NAME="$MODE_NAME"

# Wait for display to become available (max 20 seconds)
for i in {1..20}; do
    DISPLAY_NAME=\$(xrandr | grep " connected" | awk '{print \$1}')
    if [ -n "\$DISPLAY_NAME" ]; then
        echo "Display detected: \$DISPLAY_NAME"
        break
    fi
    sleep 1
done

if [ -z "\$DISPLAY_NAME" ]; then
    echo "No display found after waiting. Exiting."
    exit 1
fi

# Ensure mode exists
xrandr | grep -q "\$MODE_NAME" || {
    xrandr --newmode "\$MODE_NAME" $(cvt $WIDTH $HEIGHT $REFRESH | grep Modeline | cut -d' ' -f3-) 2>/dev/null || true
}

# Add and apply mode
xrandr --addmode "\$DISPLAY_NAME" "\$MODE_NAME" 2>/dev/null || true
xrandr --output "\$DISPLAY_NAME" --mode "\$MODE_NAME"
EOF

    chmod +x "$STARTUP_SCRIPT"
    
    # Create desktop autostart entry
    cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Exec=$STARTUP_SCRIPT
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set 2560x1440 Resolution
Comment=Apply custom resolution after login
EOF

    chmod +x "$AUTOSTART_FILE"
    
    echo "Autostart configuration complete. Resolution will be applied automatically after login."
else
    echo "Autostart not configured."
fi

echo "All done."
