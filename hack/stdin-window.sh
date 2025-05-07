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
BOLD="\033[1m"
DIM="\033[2m"
BLUE="\033[34m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
GRAY="\033[90m"
WHITE="\033[97m"
BG_BLUE="\033[44m"
BG_BLACK="\033[40m"

# Border styling
BORDER_VERT="${BLUE}│${RESET}"
BORDER_TOP="${BLUE}┌$RESET"
BORDER_BOTTOM="${BLUE}└$RESET"
BORDER_FILL="${BLUE}─$RESET"

# Determine terminal width
term_width=$(tput cols)
border_width=$((term_width - 2))

tput sc
tput civis
trap 'tput cnorm; tput rc; tput ed; exit' INT TERM EXIT

# Initialize the lines array
declare -a lines=()
for ((i=0; i<height; i++)); do
    lines[i]=""
done

# Draw the top border
draw_top_border() {
    echo -e "${BORDER_TOP}$(printf "%${border_width}s" | tr ' ' '─')${BLUE}┐${RESET}"
}

# Draw message type with appropriate color
colorize_log_level() {
    local line="$1"
    
    # Detect log level by common patterns and colorize
    if [[ "$line" =~ \[(INFO|info)\] ]]; then
        line="${line//\[INFO\]/${CYAN}[INFO]${RESET}}"
        line="${line//\[info\]/${CYAN}[info]${RESET}}"
    elif [[ "$line" =~ \[(DEBUG|debug)\] ]]; then
        line="${line//\[DEBUG\]/${MAGENTA}[DEBUG]${RESET}}"
        line="${line//\[debug\]/${MAGENTA}[debug]${RESET}}"
    elif [[ "$line" =~ \[(ERROR|error|ERR|err)\] ]]; then
        line="${line//\[ERROR\]/${RED}[ERROR]${RESET}}"
        line="${line//\[error\]/${RED}[error]${RESET}}"
        line="${line//\[ERR\]/${RED}[ERR]${RESET}}"
        line="${line//\[err\]/${RED}[err]${RESET}}"
    elif [[ "$line" =~ \[(WARN|warn|WARNING|warning)\] ]]; then
        line="${line//\[WARN\]/${YELLOW}[WARN]${RESET}}"
        line="${line//\[warn\]/${YELLOW}[warn]${RESET}}"
        line="${line//\[WARNING\]/${YELLOW}[WARNING]${RESET}}"
        line="${line//\[warning\]/${YELLOW}[warning]${RESET}}"
    elif [[ "$line" =~ \[(SUCCESS|success|OK|ok)\] ]]; then
        line="${line//\[SUCCESS\]/${GREEN}[SUCCESS]${RESET}}"
        line="${line//\[success\]/${GREEN}[success]${RESET}}"
        line="${line//\[OK\]/${GREEN}[OK]${RESET}}"
        line="${line//\[ok\]/${GREEN}[ok]${RESET}}"
    fi
    
    # Colorize timestamps in the format [HH:MM:SS] or YYYY-MM-DD HH:MM:SS
    if [[ "$line" =~ \[[0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]; then
        line=$(echo "$line" | sed -E "s/\[([0-9]{2}:[0-9]{2}:[0-9]{2})\]/${GRAY}[\1]${RESET}/g")
    fi
    if [[ "$line" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        line=$(echo "$line" | sed -E "s/([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})/${GRAY}\1${RESET}/g")
    fi
    
    # Emphasize important keywords
    line=$(echo "$line" | sed -E "s/(completed|finished|done)/${GREEN}\1${RESET}/gi")
    line=$(echo "$line" | sed -E "s/(failed|error|fatal)/${RED}\1${RESET}/gi")
    line=$(echo "$line" | sed -E "s/(warning|warn|caution)/${YELLOW}\1${RESET}/gi")
    
    echo "$line"
}

redraw_display() {
    tput rc
    tput ed
    
    # Draw the top border
    draw_top_border
    
    # Draw each line with the left border
    for ((i=0; i<height; i++)); do
        if [[ -n "${lines[i]}" ]]; then
            colored_line=$(colorize_log_level "${lines[i]}")
            echo -e "${BORDER_VERT} ${colored_line}"
        else
            echo -e "${BORDER_VERT}"
        fi
    done
    
    # Draw the bottom border
    echo -e "${BORDER_BOTTOM}$(printf "%${border_width}s" | tr ' ' '─')${BLUE}┘${RESET}"
}

line_count=0
while IFS= read -r line; do
    if [[ $line_count -ge $height ]]; then
        for ((i=0; i<height-1; i++)); do
            lines[i]="${lines[i+1]}"
        done
        lines[$((height-1))]="$line"
    else
        lines[$line_count]="$line"
        ((line_count++))
    fi
    
    redraw_display
done

exit 0
