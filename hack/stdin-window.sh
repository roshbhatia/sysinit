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

# Use a much simpler Ruby script
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

# Get terminal width - fallback to 80 if not available
term_width = ENV['COLUMNS'] ? ENV['COLUMNS'].to_i : 80

# Height from bash variable
height = $height

# Buffer to store log lines
buffer = []

# Draw border
def draw_border(width)
  \"#{BLUE}+#{'-' * (width - 2)}+#{RESET}\"
end

# Process a log line with colors
def colorize_log(line, is_latest)
  # Add prefix and make light gray
  result = is_latest ? \"> #{LIGHT_GRAY}#{line}#{RESET}\" : \"  #{LIGHT_GRAY}#{line}#{RESET}\"
  
  # Simple replacements for log levels
  result = result.gsub('[INFO]', \"#{CYAN}[INFO]#{LIGHT_GRAY}\")
  result = result.gsub('[info]', \"#{CYAN}[info]#{LIGHT_GRAY}\")
  result = result.gsub('[DEBUG]', \"#{MAGENTA}[DEBUG]#{LIGHT_GRAY}\")
  result = result.gsub('[debug]', \"#{MAGENTA}[debug]#{LIGHT_GRAY}\")
  result = result.gsub('[ERROR]', \"#{RED}[ERROR]#{LIGHT_GRAY}\")
  result = result.gsub('[error]', \"#{RED}[error]#{LIGHT_GRAY}\")
  result = result.gsub('[WARN]', \"#{YELLOW}[WARN]#{LIGHT_GRAY}\")
  result = result.gsub('[warn]', \"#{YELLOW}[warn]#{LIGHT_GRAY}\")
  
  # Done with basic coloring
  result
end

# Update the display
def update_display(buffer, height, width)
  # Clear screen
  puts \"\033[2J\033[H\"
  
  # Draw top border
  puts draw_border(width)
  
  # Calculate empty lines needed
  empty_lines = [0, height - buffer.size].max
  
  # Print empty lines
  empty_lines.times { puts \"\" }
  
  # Print all log lines
  buffer.each_with_index do |line, idx|
    puts colorize_log(line, idx == buffer.size - 1)
  end
  
  # Draw bottom border
  puts draw_border(width)
end

# Main loop
begin
  while line = STDIN.gets
    line = line.chomp
    
    # Add to buffer
    buffer << line
    
    # Keep buffer at maximum size
    buffer.shift if buffer.size > height
    
    # Update display
    update_display(buffer, height, term_width)
  end
rescue Interrupt
  exit 0
rescue Exception => e
  puts \"Error: \#{e.message}\"
  exit 1
end
" || echo "Ruby script failed with an error."

exit 0
