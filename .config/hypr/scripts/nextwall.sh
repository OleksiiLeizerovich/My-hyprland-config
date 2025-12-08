#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper_path.txt"

mapfile -t ALL_WALLPAPERS < <(find "$WALLPAPER_DIR" -type f | sort)

if [ ${#ALL_WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

CURRENT_WALLPAPER=""
if [ -f "$STATE_FILE" ]; then
    CURRENT_WALLPAPER=$(cat "$STATE_FILE")
fi

CURRENT_INDEX=-1
for i in "${!ALL_WALLPAPERS[@]}"; do
    if [[ "${ALL_WALLPAPERS[$i]}" == "$CURRENT_WALLPAPER" ]]; then
        CURRENT_INDEX=$i
        break
    fi
done

NEXT_INDEX=$((CURRENT_INDEX + 1))

if [ $NEXT_INDEX -ge ${#ALL_WALLPAPERS[@]} ]; then
    NEXT_INDEX=0
fi

WALLPAPER_PATH="${ALL_WALLPAPERS[$NEXT_INDEX]}"
echo "Setting wallpaper: $WALLPAPER_PATH"

EXTENSION="${WALLPAPER_PATH##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

case "$EXTENSION_LOWER" in
    jpg|jpeg|png|gif|webp|bmp)
        pkill mpvpaper
        swww img "$WALLPAPER_PATH" \
            --transition-type grow --transition-fps 60 \
            --transition-duration 1.0 --transition-pos 0.824,0.941
        ;;
    mp4|mkv|mov|avi|webm)
        pkill mpvpaper
        mpvpaper -o "loop" "*" "$WALLPAPER_PATH" &
	sleep 0.1
        ;;
    *)
        echo "Unsupported file type: $EXTENSION_LOWER. Skipping."
        exit 1
        ;;
esac

wal -i "$WALLPAPER_PATH" -n -q
source "$HOME/.cache/wal/colors.sh"
active_border_col="${color7:1}"
inactive_border_col="${color0:1}"
hyprctl keyword general:col.active_border "0xff$active_border_col"
hyprctl keyword general:col.inactive_border "0xff$inactive_border_col"
pkill waybar
waybar &

echo "$WALLPAPER_PATH" > "$STATE_FILE"

echo "Wallpaper and theme updated"
