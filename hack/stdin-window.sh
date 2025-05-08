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

# Use Python to handle the sliding window display
python3 -c "
import sys
import re
import os
import time
import fcntl
import termios
import struct

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

# Get terminal size
def get_terminal_size():
    h, w = struct.unpack('HHHH', 
                         fcntl.ioctl(0, termios.TIOCGWINSZ,
                                    struct.pack('HHHH', 0, 0, 0, 0)))[:2]
    return w, h

# Terminal width
term_width, _ = get_terminal_size()

# Maximum height from bash variable
height = $height

# Buffer to store log lines
buffer = []

# Draw border
def draw_border():
    return f'{BLUE}+{'-' * term_width}+{RESET}'

# Process a log line with colors
def colorize_log(line, is_latest=False):
    # Make line light gray by default
    result = f'{LIGHT_GRAY}{line}{RESET}'
    
    # Add prefix to latest line
    if is_latest:
        result = f'> {result}'
    else:
        result = f'  {result}'
    
    # Color log levels
    patterns = [
        (r'\[(INFO|info)\]', f'{CYAN}\\\\g<0>{LIGHT_GRAY}'),
        (r'\[(DEBUG|debug)\]', f'{MAGENTA}\\\\g<0>{LIGHT_GRAY}'),
        (r'\[(ERROR|error|ERR|err)\]', f'{RED}\\\\g<0>{LIGHT_GRAY}'),
        (r'\[(WARN|warn|WARNING|warning)\]', f'{YELLOW}\\\\g<0>{LIGHT_GRAY}'),
        (r'\[(SUCCESS|success|OK|ok)\]', f'{GREEN}\\\\g<0>{LIGHT_GRAY}'),
        (r'\[([0-9]{2}:[0-9]{2}:[0-9]{2})\]', f'{GRAY}\\\\g<0>{LIGHT_GRAY}'),
        (r'(completed|finished|done)', f'{GREEN}\\\\g<0>{LIGHT_GRAY}'),
        (r'(failed|error|fatal)', f'{RED}\\\\g<0>{LIGHT_GRAY}'),
        (r'(warning|warn|caution)', f'{YELLOW}\\\\g<0>{LIGHT_GRAY}')
    ]
    
    for pattern, replacement in patterns:
        result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)
    
    return result

# Update the display
def update_display():
    # Clear screen and move cursor to top-left
    print('\033[2J\033[H', end='')
    
    # Draw top border
    print(draw_border())
    
    # Calculate empty space needed
    filled_lines = len(buffer)
    empty_lines = height - filled_lines
    
    # Print empty lines to push content to bottom
    for _ in range(empty_lines):
        print()
    
    # Print all log lines
    for i, line in enumerate(buffer):
        is_latest = (i == len(buffer) - 1)
        print(colorize_log(line, is_latest))
    
    # Draw bottom border
    print(draw_border())
    sys.stdout.flush()

# Main loop
try:
    for line in sys.stdin:
        line = line.rstrip()
        
        # Add to buffer
        buffer.append(line)
        
        # Keep buffer at maximum size
        if len(buffer) > height:
            buffer.pop(0)
        
        # Update the display
        update_display()
        
except KeyboardInterrupt:
    sys.exit(0)
" || echo "Python script failed. Make sure Python 3 is installed."

exit 0
