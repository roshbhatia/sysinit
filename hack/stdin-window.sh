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

# Use Ruby for the sliding window display
/usr/bin/ruby -e "
# ANSI color codes
RESET = '\033[0m'
BLUE = '\033[34m'
CYAN = '\033[36m'
GREEN = '\033[32m'
YELLOW = '\033[33m'
RED = '\033[31m'
MAGENTA = '\033[35m'
GRAY = '\033[90m'
LIGHT_GRAY = '\033[37m'

# Get terminal width
term_width = \`tput cols\`.to_i rescue 80

# Height from bash variable
height = $height

# Buffer to store log lines
buffer = []

# Draw border
def draw_border(width)
  \"#{BLUE}+#{'-' * (width - 2)}+#{RESET}\"
end

# Process a log line with colors
def colorize_log(line, is_latest = false)
  # Make line light gray by default
  result = \"#{LIGHT_GRAY}#{line}#{RESET}\"
  
  # Add prefix to latest line
  prefix = is_latest ? '> ' : '  '
  result = \"#{prefix}#{result}\"
  
  # Color log levels
  result = result.gsub(/\\[(INFO|info)\\]/) { \"#{CYAN}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/\\[(DEBUG|debug)\\]/) { \"#{MAGENTA}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/\\[(ERROR|error|ERR|err)\\]/) { \"#{RED}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/\\[(WARN|warn|WARNING|warning)\\]/) { \"#{YELLOW}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/\\[(SUCCESS|success|OK|ok)\\]/) { \"#{GREEN}#{$&}#{LIGHT_GRAY}\" }
  
  # Color timestamps
  result = result.gsub(/\\[\\d{2}:\\d{2}:\\d{2}\\]/) { \"#{GRAY}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})/) { \"#{GRAY}#{$&}#{LIGHT_GRAY}\" }
  
  # Color keywords
  result = result.gsub(/(completed|finished|done)/i) { \"#{GREEN}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/(failed|error|fatal)/i) { \"#{RED}#{$&}#{LIGHT_GRAY}\" }
  result = result.gsub(/(warning|warn|caution)/i) { \"#{YELLOW}#{$&}#{LIGHT_GRAY}\" }
  
  result
end

# Update the display
def update_display(buffer, height, term_width)
  # Clear screen and move cursor to top-left
  print \"\033[2J\033[H\"
  
  # Draw top border
  puts draw_border(term_width)
  
  # Calculate empty space needed
  filled_lines = buffer.size
  empty_lines = height - filled_lines
  
  # Print empty lines to push content to bottom
  empty_lines.times { puts \"\" }
  
  # Print all log lines
  buffer.each_with_index do |line, i|
    is_latest = (i == buffer.size - 1)
    puts colorize_log(line, is_latest)
  end
  
  # Draw bottom border
  puts draw_border(term_width)
  $stdout.flush
end

# Main loop
begin
  while line = gets
    line = line.chomp
    
    # Add to buffer
    buffer << line
    
    # Keep buffer at maximum size
    buffer.shift if buffer.size > height
    
    # Update the display
    update_display(buffer, height, term_width)
  end
rescue Interrupt
  exit
end
" || echo "Ruby script failed with an error."

exit 0
