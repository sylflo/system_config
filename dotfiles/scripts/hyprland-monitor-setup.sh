#!/usr/bin/env bash
# Hyprland monitor setup script
# Automatically configures monitors based on what's connected

# Wait a moment for monitors to be fully detected
sleep 1

# Get list of connected monitor names
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

if echo "$MONITORS" | grep -q "DP-4"; then
    # Home setup: dual external monitors, disable laptop screen
    echo "Detected home setup (DP-4 + DP-3)"
    hyprctl keyword monitor "DP-4,1920x1080@60,0x0,1"
    hyprctl keyword monitor "DP-3,1920x1080@60,1920x0,1"
    hyprctl keyword monitor "eDP-1,disable"
elif echo "$MONITORS" | grep -q "DP-2"; then
    # Office setup: laptop screen + external monitor
    echo "Detected office setup (eDP-1 + DP-2)"
    hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
    hyprctl keyword monitor "DP-2,1920x1080@60,1920x0,1"
else
    # Mobile setup: laptop screen only
    echo "Detected mobile setup (eDP-1 only)"
    hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
fi
