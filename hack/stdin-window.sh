#!/bin/bash
# shellcheck disable=all

# Default height
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
LIGHT_GRAY="\033[37m"

# Get terminal width or use default
term_width=$(tput cols 2>/dev/null || echo 80)

# Draw borders
function draw_border {
  echo -e "${BLUE}+$(printf '%*s' $((term_width-2)) | tr ' ' '-')+${RESET}"
}

# Initialize buffer array
declare -a buffer=()

# Hide cursor
tput civis 2>/dev/null

# Restore cursor on exit
trap 'tput cnorm 2>/dev/null; exit' INT TERM EXIT

# Main loop
while IFS= read -r line; do
  # Add to buffer
  buffer+=("$line")
  
  # Keep buffer at maximum size
  if [[ ${#buffer[@]} -gt $height ]]; then
    # Remove oldest entry by re-slicing the array
    buffer=("${buffer[@]:1}")
  fi
  
  # Clear screen
  clear
  
  # Draw top border
  draw_border
  
  # Calculate empty lines
  empty_lines=$((height - ${#buffer[@]}))
  
  # Print empty lines
  for ((i=0; i<empty_lines; i++)); do
    echo ""
  done
  
  # Print all log lines
  for ((i=0; i<${#buffer[@]}; i++)); do
    if [[ $i -eq $((${#buffer[@]} - 1)) ]]; then
      # Latest entry with prefix
      echo -e "> ${LIGHT_GRAY}${buffer[$i]}${RESET}"
    else
      # Older entries
      echo -e "  ${LIGHT_GRAY}${buffer[$i]}${RESET}"
    fi
  done
  
  # Draw bottom border
  draw_border
done

# Show cursor
tput cnorm 2>/dev/null

exit 0
