#!/bin/bash
# shellcheck disable=SC2004

# Default settings
height=16
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

# Simple function to draw the header
draw_header() {
    local width=$(tput cols)
    local top_border="╭$(printf '─%.0s' $(seq 1 $((width - 2))))╮"
    local bottom_border="╰$(printf '─%.0s' $(seq 1 $((width - 2))))╯"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    # Apply color to border if a color was specified
    if [[ "$window_color" =~ ^[0-9]+$ ]]; then
        printf "\033[38;5;%sm%s\033[0m\n" "$window_color" "$top_border"
        
        if [[ "$title_align" == "center" ]]; then
            printf "\033[38;5;%sm%s\033[0m\n" "$window_color" "$(printf "%*s%s%*s" "$padding" "" "$title" "$padding" "")"
        elif [[ "$title_align" == "left" ]]; then
            printf "\033[38;5;%sm%s\033[0m\n" "$window_color" "$(printf " %s%*s" "$title" $((width - ${#title} - 2)) "")"
        elif [[ "$title_align" == "right" ]]; then
            printf "\033[38;5;%sm%s\033[0m\n" "$window_color" "$(printf "%*s%s " $((width - ${#title} - 2)) "" "$title")"
        fi
        
        printf "\033[38;5;%sm%s\033[0m\n" "$window_color" "$bottom_border"
    else
        # Default color
        echo "$top_border"
        
        if [[ "$title_align" == "center" ]]; then
            printf "%*s%s%*s\n" "$padding" "" "$title" "$padding" ""
        elif [[ "$title_align" == "left" ]]; then
            printf " %s%*s\n" "$title" $((width - ${#title} - 2)) ""
        elif [[ "$title_align" == "right" ]]; then
            printf "%*s%s \n" $((width - ${#title} - 2)) "" "$title"
        fi
        
        echo "$bottom_border"
    fi
}

# Draw the header
draw_header

# Process input and display with color if specified
if [[ "$text_color" =~ ^[0-9]+$ ]]; then
    # Read input and apply color
    while IFS= read -r line; do
        printf "\033[38;5;%sm%s\033[0m\n" "$text_color" "$line"
    done
else
    # Just pass through the input
    cat
fi

exit 0
