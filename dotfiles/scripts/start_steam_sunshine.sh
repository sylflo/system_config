#!/usr/bin/env bash

# Move to workspace 2
hyprctl dispatch workspace 2

# Launch Steam Big Picture in detached mode
setsid /run/current-system/sw/bin/steam steam://open/bigpicture &

# Give it a few seconds to initialize
sleep 10

# Turn off monitors
/etc/profiles/per-user/sylflo/bin/ddcutil --bus=1 setvcp D6 4
/etc/profiles/per-user/sylflo/bin/ddcutil --bus=2 setvcp D6 4

