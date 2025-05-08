#!/bin/bash
# shellcheck disable=all
height=32
while [[ $# -gt 0 ]]; do
case *$1* in
--height)
height="*$2*"
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
LIGHT_GRAY="\033[37m"
WHITE="\033[97m"
BG_BLUE="\033[44m"
BG_BLACK="\033[40m"

# Border styling
BORDER_TOP="${BLUE}+${RESET}"
BORDER_BOTTOM="${BLUE}+${RESET}"
BORDER_FILL="${BLUE}-${RESET}"

# Determine terminal width
term_width=$(tput cols)
border_width=$((term_width))

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
    echo -e "${BORDER_TOP}$(printf "%${border_width}s" | tr ' ' '-')${BLUE}+${RESET}"
}

# Draw the bottom border
draw_bottom_border() {
    echo -e "${BORDER_BOTTOM}$(printf "%${border_width}s" | tr ' ' '-')${BLUE}+${RESET}"
}

# Draw message type with appropriate color
colorize_log_level() {
    local line="*$1*"
    local is_latest="$2"
    
    # Apply light gray base color for all logs
    line="${LIGHT_GRAY}${line}${RESET}"
    
    # Add ">" prefix for most recent log
    if [[ "$is_latest" == "true" ]]; then
        line="> $line"
    else
        line="  $line"
    fi
    
    # Detect log level by common patterns and colorize
    if [[ "$line" =~ \[(INFO|info)\] ]]; then
        line="${line//\[INFO\]/${CYAN}[INFO]${LIGHT_GRAY}}"
        line="${line//\[info\]/${CYAN}[info]${LIGHT_GRAY}}"
    elif [[ "$line" =~ \[(DEBUG|debug)\] ]]; then
        line="${line//\[DEBUG\]/${MAGENTA}[DEBUG]${LIGHT_GRAY}}"
        line="${line//\[debug\]/${MAGENTA}[debug]${LIGHT_GRAY}}"
    elif [[ "$line" =~ \[(ERROR|error|ERR|err)\] ]]; then
        line="${line//\[ERROR\]/${RED}[ERROR]${LIGHT_GRAY}}"
        line="${line//\[error\]/${RED}[error]${LIGHT_GRAY}}"
        line="${line//\[ERR\]/${RED}[ERR]${LIGHT_GRAY}}"
        line="${line//\[err\]/${RED}[err]${LIGHT_GRAY}}"
    elif [[ "$line" =~ \[(WARN|warn|WARNING|warning)\] ]]; then
        line="${line//\[WARN\]/${YELLOW}[WARN]${LIGHT_GRAY}}"
        line="${line//\[warn\]/${YELLOW}[warn]${LIGHT_GRAY}}"
        line="${line//\[WARNING\]/${YELLOW}[WARNING]${LIGHT_GRAY}}"
        line="${line//\[warning\]/${YELLOW}[warning]${LIGHT_GRAY}}"
    elif [[ "$line" =~ \[(SUCCESS|success|OK|ok)\] ]]; then
        line="${line//\[SUCCESS\]/${GREEN}[SUCCESS]${LIGHT_GRAY}}"
        line="${line//\[success\]/${GREEN}[success]${LIGHT_GRAY}}"
        line="${line//\[OK\]/${GREEN}[OK]${LIGHT_GRAY}}"
        line="${line//\[ok\]/${GREEN}[ok]${LIGHT_GRAY}}"
    fi
    
    # Colorize timestamps in the format [HH:MM:SS] or YYYY-MM-DD HH:MM:SS
    if [[ "$line" =~ \[[0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]; then
        line=$(echo "$line" | sed -E "s/\[([0-9]{2}:[0-9]{2}:[0-9]{2})\]/${GRAY}[\1]${LIGHT_GRAY}/g")
    fi
    if [[ "$line" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        line=$(echo "$line" | sed -E "s/([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})/${GRAY}\1${LIGHT_GRAY}/g")
    fi
    
    # Emphasize important keywords
    line=$(echo "$line" | sed -E "s/(completed|finished|done)/${GREEN}\1${LIGHT_GRAY}/gi")
    line=$(echo "$line" | sed -E "s/(failed|error|fatal)/${RED}\1${LIGHT_GRAY}/gi")
    line=$(echo "$line" | sed -E "s/(warning|warn|caution)/${YELLOW}\1${LIGHT_GRAY}/gi")
    
    echo "$line"
}

redraw_display() {
    tput rc
    tput ed
    
    # Draw the top border
    draw_top_border
    
    # Calculate how many empty lines we need at the top to push content to bottom
    local filled_lines=0
    for ((i=0; i<height; i++)); do
        if [[ -n "${lines[i]}" ]]; then
            ((filled_lines++))
        fi
    done
    
    local empty_lines=$((height - filled_lines))
    
    # Print empty lines first to push content to bottom
    for ((i=0; i<empty_lines; i++)); do
        echo ""
    done
    
    # Draw each line from the array
    for ((i=0; i<filled_lines; i++)); do
        idx=$((i))
        is_latest="false"
        if [[ $idx -eq $((filled_lines - 1)) ]]; then
            is_latest="true"
        fi
        colored_line=$(colorize_log_level "${lines[idx]}" "$is_latest")
        echo -e "$colored_line"
    done
    
    # Draw the bottom border
    draw_bottom_border
}

# Circular buffer logic to handle log entries
line_count=0
while IFS= read -r line; do
    if [[ $line_count -ge $height ]]; then
        # Shift array up (remove oldest entry)
        for ((i=0; i<height-1; i++)); do
            lines[i]="${lines[i+1]}"
        done
        # Add new entry to bottom
        lines[$((height-1))]="$line"
    else
        # Still filling initial buffer
        lines[$line_count]="$line"
        ((line_count++))
    fi
    redraw_display
done

exit 0
