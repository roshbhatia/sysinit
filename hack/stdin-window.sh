#!/bin/bash
# shellcheck disable=all

height=32
while [[ $# -gt 0 ]]; do
  case "$1" in
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
LIGHT_GRAY="\033[37m"

# Determine terminal width
term_width=$(tput cols)

# Initialize the buffer
declare -a buffer=()

# Setup terminal
tput civis  # Hide cursor
trap 'tput cnorm; exit' INT TERM EXIT

# Draw borders
draw_border() {
  echo -e "${BLUE}+$(printf "%${term_width}s" | tr ' ' '-')+${RESET}"
}

# Process a log line with colors
colorize_log() {
  local line="$1"
  local is_latest="$2"
  
  # Make line light gray by default
  line="${LIGHT_GRAY}${line}${RESET}"
  
  # Add prefix to latest line
  if [[ "$is_latest" == "true" ]]; then
    line="> $line"
  else
    line="  $line"
  fi
  
  # Color log levels
  line=$(echo "$line" | sed -E "s/\[(INFO|info)\]/${CYAN}[&]${LIGHT_GRAY}/g")
  line=$(echo "$line" | sed -E "s/\[(DEBUG|debug)\]/${MAGENTA}[&]${LIGHT_GRAY}/g")
  line=$(echo "$line" | sed -E "s/\[(ERROR|error|ERR|err)\]/${RED}[&]${LIGHT_GRAY}/g")
  line=$(echo "$line" | sed -E "s/\[(WARN|warn|WARNING|warning)\]/${YELLOW}[&]${LIGHT_GRAY}/g")
  line=$(echo "$line" | sed -E "s/\[(SUCCESS|success|OK|ok)\]/${GREEN}[&]${LIGHT_GRAY}/g")
  
  # Color timestamps
  line=$(echo "$line" | sed -E "s/\[([0-9]{2}:[0-9]{2}:[0-9]{2})\]/${GRAY}[&]${LIGHT_GRAY}/g")
  
  # Color keywords
  line=$(echo "$line" | sed -E "s/(completed|finished|done)/${GREEN}&${LIGHT_GRAY}/gi")
  line=$(echo "$line" | sed -E "s/(failed|error|fatal)/${RED}&${LIGHT_GRAY}/gi")
  line=$(echo "$line" | sed -E "s/(warning|warn|caution)/${YELLOW}&${LIGHT_GRAY}/gi")
  
  echo -e "$line"
}

# Draw the entire display
update_display() {
  clear
  
  # Draw top border
  draw_border
  
  # Calculate empty space needed at top
  local filled_lines=${#buffer[@]}
  local empty_lines=$((height - filled_lines))
  
  # Print empty lines to push content to bottom
  for ((i=0; i<empty_lines; i++)); do
    echo ""
  done
  
  # Print all log lines
  for ((i=0; i<filled_lines; i++)); do
    is_latest="false"
    if [[ $i -eq $((filled_lines - 1)) ]]; then
      is_latest="true"
    fi
    colorize_log "${buffer[i]}" "$is_latest"
  done
  
  # Draw bottom border
  draw_border
}

# Main processing loop
while IFS= read -r line; do
  # Add line to buffer
  buffer+=("$line")
  
  # Keep buffer at maximum size
  if [[ ${#buffer[@]} -gt $height ]]; then
    # Remove oldest entry
    buffer=("${buffer[@]:1}")
  fi
  
  # Update display
  update_display
done

tput cnorm # Show cursor
exit 0
