#!/usr/bin/env bash
# Alacritty Theme Switcher for Shinkai themes
# Usage: alacritty-theme-switch.sh [light|dark|toggle]

THEME_DIR="$HOME/.config/alacritty/themes"
CURRENT_LINK="$THEME_DIR/shinkai-current.toml"
DARK_THEME="$THEME_DIR/shinkai-dark.toml"
LIGHT_THEME="$THEME_DIR/shinkai-light.toml"
STATE_FILE="$HOME/.config/alacritty/current-theme"

# Function to switch to a theme
switch_theme() {
    local theme=$1
    local theme_file=""

    if [ "$theme" = "dark" ]; then
        theme_file="$DARK_THEME"
        echo "dark" > "$STATE_FILE"
        echo "Switched to Shinkai Dark theme"
    elif [ "$theme" = "light" ]; then
        theme_file="$LIGHT_THEME"
        echo "light" > "$STATE_FILE"
        echo "Switched to Shinkai Light theme"
    else
        echo "Error: Unknown theme '$theme'"
        echo "Usage: $0 [light|dark|toggle]"
        exit 1
    fi

    # Create or update symlink
    ln -sf "$theme_file" "$CURRENT_LINK"

    # Reload all Alacritty instances
    # This sends a signal to reload the config
    touch ~/.config/alacritty/alacritty.toml 2>/dev/null || true
}

# Get current theme
get_current_theme() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "dark"  # Default to dark
    fi
}

# Main logic
case "${1:-toggle}" in
    dark)
        switch_theme "dark"
        ;;
    light)
        switch_theme "light"
        ;;
    toggle)
        current=$(get_current_theme)
        if [ "$current" = "dark" ]; then
            switch_theme "light"
        else
            switch_theme "dark"
        fi
        ;;
    status)
        echo "Current theme: $(get_current_theme)"
        ;;
    *)
        echo "Usage: $0 [light|dark|toggle|status]"
        echo "  light  - Switch to light theme"
        echo "  dark   - Switch to dark theme"
        echo "  toggle - Toggle between themes (default)"
        echo "  status - Show current theme"
        exit 1
        ;;
esac
