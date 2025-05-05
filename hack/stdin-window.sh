#!/bin/bash

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

tput civis
trap "tput cnorm; clear; exit" INT TERM EXIT

draw_border() {
    local width
    local top_border
    local bottom_border
    local padding

    width=$(tput cols)
    top_border="╭$(printf '─%.0s' $(seq 1 $((width - 2))))╮"
    bottom_border="╰$(printf '─%.0s' $(seq 1 $((width - 2))))╯"
    padding=$(( (width - ${#title} - 2) / 2 ))

    echo -e "\033[${window_color}m"
    echo "$top_border"

    if [[ "$title_align" == "center" ]]; then
        printf "%*s%s%*s\n" "$padding" "" "$title" "$padding" ""
    elif [[ "$title_align" == "left" ]]; then
        printf " %s%*s\n" "$title" $((width - ${#title} - 2)) ""
    elif [[ "$title_align" == "right" ]]; then
        printf "%*s%s \n" $((width - ${#title} - 2)) "" "$title"
    fi

    echo "$bottom_border"
    echo -e "\033[0m"
}

main() {
    # Create a buffer to store up to $height lines
    declare -a buffer
    local line_count=0
    
    while IFS= read -r line; do
        # Add line to buffer
        # shellcheck disable=SC2004
        buffer[$line_count]="$line"
        ((line_count++))
        
        # Keep only the last $height lines
        if [ $line_count -gt "$height" ]; then
            # Shift array to remove oldest entry
            buffer=("${buffer[@]:1}")
            ((line_count--))
        fi
        
        # Display current buffer
        clear
        draw_border
        
        # Display each line in the buffer with text color
        for i in "${!buffer[@]}"; do
            echo -e "\033[38;5;${text_color}m${buffer[$i]}\033[0m"
        done
    done
}

main
