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

# Extremely simple version with minimal dependencies
/usr/bin/ruby -e "
# ANSI color codes
RESET = '\033[0m'
BLUE = '\033[34m'
LIGHT_GRAY = '\033[37m'

# Height from bash variable
height = $height
width = 80

# Buffer to store log lines
buffer = []

# Main loop
begin
  STDIN.each_line do |line|
    line = line.chomp
    
    # Add to buffer
    buffer << line
    
    # Keep buffer at maximum size
    buffer.shift if buffer.size > height
    
    # Clear screen
    print \"\033[2J\033[H\"
    
    # Draw top border
    puts \"#{BLUE}+#{'-' * (width - 2)}+#{RESET}\"
    
    # Calculate empty lines needed
    empty_lines = [0, height - buffer.size].max
    
    # Print empty lines
    empty_lines.times { puts \"\" }
    
    # Print all log lines
    buffer.each_with_index do |line, idx|
      prefix = idx == buffer.size - 1 ? '> ' : '  '
      puts \"#{prefix}#{LIGHT_GRAY}#{line}#{RESET}\"
    end
    
    # Draw bottom border
    puts \"#{BLUE}+#{'-' * (width - 2)}+#{RESET}\"
  end
rescue Exception => e
  # Just exit silently on any error
  exit 0
end
" || {
  # Pure bash fallback if Ruby fails
  while read -r line; do
    clear
    echo -e "\033[34m+------------------------------------------------------------------------------+\033[0m"
    echo -e "> \033[37m$line\033[0m"
    echo -e "\033[34m+------------------------------------------------------------------------------+\033[0m"
  done
}

exit 0
