#!/bin/bash

# Шлях до зображення
WALLPAPER_PATH="$1"

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "No such file: $WALLPAPER_PATH"
    exit 1
fi

swww img "$WALLPAPER_PATH" \
    --transition-type grow \
    --transition-fps 60 \
    --transition-duration 1.0 \
    --transition-pos 0.824,0.941

wal -i "$WALLPAPER_PATH" -n -q

source "$HOME/.cache/wal/colors.sh"

active_border_col="${color7:1}"
inactive_border_col="${color0:1}"

hyprctl keyword general:col.active_border "0xff$active_border_col"
hyprctl keyword general:col.inactive_border "0xff$inactive_border_col"

# Наприклад, для Waybar:
pkill waybar
waybar &

echo "Wallapepr and theme updated"
