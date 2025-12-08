#!/usr/bin/env bash
# Daemon that listens to Hyprland workspace changes and switches wallpapers
# Every workspace switch picks a new random wallpaper with swww animations

set -euo pipefail

# Wallpaper directory
readonly WALLPAPER_DIR="$HOME/Pictures/Wallpapers/Themes/Makoto_Shinkai"

# Transition settings
readonly TRANSITION_TYPE="random"  # Options: simple, fade, wipe, wave, grow, center, outer, random
readonly TRANSITION_FPS=60
readonly TRANSITION_DURATION=2

# Function to switch wallpaper
switch_wallpaper() {
  local workspace_id="$1"

  echo "[wallpaper-daemon] Switching to workspace: $workspace_id"

  # Check if wallpaper directory exists
  if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "[wallpaper-daemon] ERROR: Wallpaper directory not found: $WALLPAPER_DIR" >&2
    return 1
  fi

  # Get all wallpapers as an array
  local wallpapers=()
  mapfile -t wallpapers < <(find -L "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | sort)

  # Check if we have wallpapers
  if [[ ${#wallpapers[@]} -eq 0 ]]; then
    echo "[wallpaper-daemon] ERROR: No wallpapers found in $WALLPAPER_DIR" >&2
    return 1
  fi

  echo "[wallpaper-daemon] Found ${#wallpapers[@]} wallpapers"

  # Always pick a random wallpaper
  local random_index=$((RANDOM % ${#wallpapers[@]}))
  local selected_wallpaper="${wallpapers[$random_index]}"

  echo "[wallpaper-daemon] Selected wallpaper: $(basename "$selected_wallpaper")"

  # Set the wallpaper with swww
  echo "[wallpaper-daemon] Applying wallpaper with transition: $TRANSITION_TYPE"
  swww img "$selected_wallpaper" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-fps "$TRANSITION_FPS" \
    --transition-duration "$TRANSITION_DURATION"

  echo "[wallpaper-daemon] Done!"
}

# Function to handle Hyprland events
handle_event() {
  local event="$1"

  case "$event" in
    workspace\>\>*)
      # Extract workspace ID from event (format: "workspace>>ID")
      local workspace_id="${event#workspace>>}"
      switch_wallpaper "$workspace_id"
      ;;
  esac
}

# Main daemon loop
main() {
  echo "[wallpaper-daemon] Starting workspace wallpaper daemon"

  # Check if Hyprland is running
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "[wallpaper-daemon] ERROR: HYPRLAND_INSTANCE_SIGNATURE not set. Is Hyprland running?" >&2
    exit 1
  fi

  # Listen to Hyprland socket for events
  local socket_path="${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  echo "[wallpaper-daemon] Socket: $socket_path"
  echo "[wallpaper-daemon] Listening for workspace changes..."
  socat -U - "UNIX-CONNECT:${socket_path}" | while read -r line; do
    handle_event "$line"
  done
}

main
