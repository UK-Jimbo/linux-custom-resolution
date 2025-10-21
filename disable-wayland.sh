#!/bin/bash

CONF_FILE="/etc/gdm3/custom.conf"

# Check if WaylandEnable is already uncommented
if grep -q "^WaylandEnable=false" "$CONF_FILE"; then
    echo "Wayland already disabled."
else
    echo "Disabling Wayland..."
    sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' "$CONF_FILE"
    echo "Wayland disabled. Restarting GDM3..."
    sudo systemctl restart gdm3
fi
