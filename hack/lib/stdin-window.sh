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

RESET="\033[0m"
BLUE="\033[34m"
LIGHT_GRAY="\033[37m"

term_width=$(tput cols 2>/dev/null || echo 80)

function draw_border {
  echo -e "${BLUE}+$(printf '%*s' $((term_width-2)) | tr ' ' '-')+${RESET}"
}

declare -a buffer=()

line_count=0

function print_buffer {
  clear
  
  draw_border
  
  local visible_lines=${#buffer[@]}
  if [[ $visible_lines -gt $height ]]; then
    visible_lines=$height
  fi
  
  local empty_lines=$((height - visible_lines))
  
  for ((i=0; i<empty_lines; i++)); do
    echo ""
  done
  
  local start_idx=0
  if [[ ${#buffer[@]} -gt $height ]]; then
    start_idx=$((${#buffer[@]} - height))
  fi
  
  for ((i=start_idx; i<${#buffer[@]}; i++)); do
    if [[ $i -eq $((${#buffer[@]} - 1)) ]]; then
      echo -e "> ${LIGHT_GRAY}${buffer[$i]}${RESET}"
    else
      echo -e "  ${LIGHT_GRAY}${buffer[$i]}${RESET}"
    fi
  done
  
  draw_border
}

tput civis 2>/dev/null

trap 'tput cnorm 2>/dev/null; exit' INT TERM EXIT

while IFS= read -r line; do
  buffer+=("$line")
  
  ((line_count++))
  
  print_buffer
done

tput cnorm 2>/dev/null

exit 0
