#!/bin/bash
# shellcheck disable=SC2004

# Default settings
height=16
text_color="8" # Default to a lighter gray (8) instead of regular text

while [[ $# -gt 0 ]]; do
    case $1 in
        --height)
            height="$2"
            shift 2
            ;;
        --text-color)
            text_color="$2"
            shift 2
            ;;
        # Keep these options for backward compatibility but ignore them
        --title)
            shift 2
            ;;
        --title-align)
            shift 2
            ;;
        --window-color)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Store the initial cursor position
tput sc

# Hide cursor
tput civis

# Set up trap to restore cursor state and clear display on exit
trap 'tput cnorm; tput rc; tput ed; exit' INT TERM EXIT

# Array to store lines
declare -a lines=()
for ((i=0; i<height; i++)); do
    lines[i]=""
done

# Set up colors
if [[ "$text_color" =~ ^[0-9]+$ ]]; then
    color_code="\033[38;5;${text_color}m"
else
    color_code="\033[0m"
fi
reset="\033[0m"

# Function to redraw the display
redraw_display() {
    # Return to saved position
    tput rc
    # Clear display area
    tput ed
    
    # Draw lines
    for ((i=0; i<${#lines[@]}; i++)); do
        if [[ -n "${lines[i]}" ]]; then
            echo -e "| ${color_code}${lines[i]}${reset}"
        fi
    done
}

# Process input line by line
line_count=0
while IFS= read -r line; do
    # Add line to buffer, shifting if necessary
    if [[ $line_count -ge $height ]]; then
        # Shift lines up
        for ((i=0; i<height-1; i++)); do
            lines[i]="${lines[i+1]}"
        done
        lines[height-1]="$line"
    else
        lines[$line_count]="$line"
        ((line_count++))
    fi
    
    # Redraw the display
    redraw_display
done

# If we get here, we're at the end of the input
exit 0
