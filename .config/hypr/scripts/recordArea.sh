#!/bin/bash

VIDEO_DIR=~/Videos/Screencasts

FILE_NAME="$(date +'%Y-%m-%d_%H-%M-%S.mp4')"
FILE_PATH="$VIDEO_DIR/$FILE_NAME"

if pgrep -x "wf-recorder" > /dev/null; then
    pkill -INT "wf-recorder"
    notify-send "🔴 Record Stopped" "$FILE_NAME"
else
    GEOMETRY=$(slurp)

    if [ -z "$GEOMETRY" ]; then
        notify-send "🔴 Record Cancelled"
        exit 1
    fi

    notify-send "🎥 Area record begins..."
    wf-recorder -a -g "$GEOMETRY" -f "$FILE_PATH"
fi
