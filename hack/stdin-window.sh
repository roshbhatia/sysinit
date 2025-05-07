#!/bin/bash
# shellcheck disable=all
height=32

while [[ $# -gt 0 ]]; do
    case $1 in
        --height)
            height="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# ANSI color codes
RESET="\033[0m"
BLUE="\033[34m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
GRAY="\033[90m"

# Clear the screen and hide cursor
clear
tput civis
trap 'tput cnorm; exit' INT TERM EXIT

# Initialize the lines array
declare -a lines=()
for ((i=0; i<height; i++)); do
    lines[i]=""
done

colorize_log_level() {
    local line="$1"
    
    # Detect log level patterns and colorize
    if [[ "$line" =~ \[(INFO|info)\] ]]; then
        line="${line//\[INFO\]/${CYAN}[INFO]${RESET}}"
        line="${line//\[info\]/${CYAN}[info]${RESET}}"
    elif [[ "$line" =~ \[(DEBUG|debug)\] ]]; then
        line="${line//\[DEBUG\]/${MAGENTA}[DEBUG]${RESET}}"
        line="${line//\[debug\]/${MAGENTA}[debug]${RESET}}"
    elif [[ "$line" =~ \[(ERROR|error|ERR|err)\] ]]; then
        line="${line//\[ERROR\]/${RED}[ERROR]${RESET}}"
        line="${line//\[error\]/${RED}[error]${RESET}}"
    elif [[ "$line" =~ \[(WARN|warn|WARNING|warning)\] ]]; then
        line="${line//\[WARN\]/${YELLOW}[WARN]${RESET}}"
        line="${line//\[warn\]/${YELLOW}[warn]${RESET}}"
    elif [[ "$line" =~ \[(SUCCESS|success|OK|ok)\] ]]; then
        line="${line//\[SUCCESS\]/${GREEN}[SUCCESS]${RESET}}"
        line="${line//\[success\]/${GREEN}[success]${RESET}}"
    fi
    
    # Colorize timestamps
    if [[ "$line" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        line=$(echo "$line" | sed -E "s/([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})/${GRAY}\1${RESET}/g")
    fi
    
    echo "$line"
}

redraw_display() {
    clear
    
    # Top border
    echo -e "${BLUE}+$(printf "%*s" $(($(tput cols)-2)) | tr ' ' '-')+${RESET}"
    
    # Content with left border
    for ((i=0; i<height; i++)); do
        if [[ -n "${lines[i]}" ]]; then
            colored_line=$(colorize_log_level "${lines[i]}")
            echo -e "${BLUE}|${RESET} ${colored_line}"
        else
            echo -e "${BLUE}|${RESET}"
        fi
    done
    
    # Bottom border
    echo -e "${BLUE}+$(printf "%*s" $(($(tput cols)-2)) | tr ' ' '-')+${RESET}"
}

# Main loop
line_count=0
while IFS= read -r line; do
    # Skip empty lines
    if [[ -z "$line" ]]; then
        continue
    fi
    
    if [[ $line_count -ge $height ]]; then
        # Shift all lines up by one
        for ((i=0; i<height-1; i++)); do
            lines[i]="${lines[i+1]}"
        done
        # Add new line at the bottom
        lines[$((height-1))]="$line"
    else
        # Fill from the top until height is reached
        lines[$line_count]="$line"
        ((line_count++))
    fi
    
    redraw_display
done

exit 0
