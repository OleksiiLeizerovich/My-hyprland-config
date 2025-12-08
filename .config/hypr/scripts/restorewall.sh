#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper_path.txt"

if [ ! -f "$STATE_FILE" ]; then
    echo "No wallpapers found. Using default one."
    mapfile -t ALL_WALLPAPERS < <(find "$WALLPAPER_DIR" -type f | sort)
    if [ ${#ALL_WALLPAPERS[@]} -gt 0 ]; then
        exec "$HOME/.config/hypr/nextwall.sh"
    fi
    exit 0
fi

WALLPAPER_PATH=$(cat "$STATE_FILE")

if [ -z "$WALLPAPER_PATH" ] || [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Incorrect path in: $WALLPAPER_PATH. Finding new one."
    rm "$STATE_FILE"
    exec "$HOME/.config/hypr/nextwall.sh"
    exit 1
fi

echo "Відновлення шпалер: $WALLPAPER_PATH"

EXTENSION="${WALLPAPER_PATH##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

case "$EXTENSION_LOWER" in
    jpg|jpeg|png|gif|webp|bmp)
        pkill mpvpaper
        swww img "$WALLPAPER_PATH" --transition-type none
        ;;
    mp4|mkv|mov|avi|webm)
        pkill mpvpaper
        mpvpaper -o "loop" "*" "$WALLPAPER_PATH" &
        ;;
    *)
        echo "Unsopported: $EXTENSION_LOWER. Skipping."
        exit 1
        ;;
esac

if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    source "$HOME/.cache/wal/colors.sh"
    active_border_col="${color7:1}"
    inactive_border_col="${color0:1}"
    hyprctl keyword general:col.active_border "0xff$active_border_col"
    hyprctl keyword general:col.inactive_border "0xff$inactive_border_col"
    pkill waybar
    waybar &
else
    wal -i "$WALLPAPER_PATH" -n -q
    source "$HOME/.cache/wal/colors.sh"
    active_border_col="${color7:1}"
    inactive_border_col="${color0:1}"
    hyprctl keyword general:col.active_border "0xff$active_border_col"
    hyprctl keyword general:col.inactive_border "0xff$inactive_border_col"
    pkill waybar
    waybar &
fi

echo "Wallpapers and theme restored"
