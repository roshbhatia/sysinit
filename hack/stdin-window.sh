#!/bin/bash
# shellcheck disable=all

# Default settings
height=20
title="Log Viewer"
title_align="center"
window_color="default"
text_color="8" # Default to a lighter gray (8) instead of regular text

while [[ $# -gt 0 ]]; do
    case $1 in
        --height)
            height="$2"
            shift 2
            ;;
        --title)
            title="$2"
            shift 2
            ;;
        --title-align)
            title_align="$2"
            shift 2
            ;;
        --window-color)
            window_color="$2"
            shift 2
            ;;
        --text-color)
            text_color="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Save cursor position and hide cursor
tput sc
tput civis
trap "tput cnorm; tput rc; exit" INT TERM EXIT

# Check if window_color is a number (ANSI color code)
if [[ "$window_color" =~ ^[0-9]+$ ]]; then
    border_color="\033[38;5;${window_color}m"
else
    border_color="\033[0m"
fi

# Check if text_color is a number (ANSI color code)
if [[ "$text_color" =~ ^[0-9]+$ ]]; then
    text_color_code="\033[38;5;${text_color}m"
else
    text_color_code="\033[0m"
fi

# Draw the initial border
draw_header() {
    local width=$(tput cols)
    local top_border="${border_color}╭$(printf '─%.0s' $(seq 1 $((width - 2))))╮\033[0m"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    local title_line=""

    if [[ "$title_align" == "center" ]]; then
        title_line="${border_color}│$(printf "%*s%s%*s" "$padding" "" "$title" "$padding" "")│\033[0m"
    elif [[ "$title_align" == "left" ]]; then
        title_line="${border_color}│ $title$(printf "%*s" $((width - ${#title} - 3)) "")│\033[0m"
    elif [[ "$title_align" == "right" ]]; then
        title_line="${border_color}│$(printf "%*s" $((width - ${#title} - 3)) "")$title │\033[0m"
    fi

    local bottom_border="${border_color}╰$(printf '─%.0s' $(seq 1 $((width - 2))))╯\033[0m"

    echo -e "$top_border"
    echo -e "$title_line"
    echo -e "$bottom_border"
}

# Draw header initially
clear
draw_header

# Create buffer array for lines
declare -a buffer=()

# Process input and update display
while IFS= read -r line; do
    # Add new line to buffer
    buffer+=("${text_color_code}${line}\033[0m")
    
    # Keep buffer at maximum height
    while [ ${#buffer[@]} -gt "$height" ]; do
        # Remove oldest line
        buffer=("${buffer[@]:1}")
    done
    
    # Clear the display area (only the content area, not the header)
    tput cup 3 0  # Position cursor after the header
    tput ed       # Clear from cursor to end of screen
    
    # Print all lines in buffer
    for i in "${!buffer[@]}"; do
        echo -e "${buffer[$i]}"
    done
done

# Restore cursor and clear control characters
tput cnorm
