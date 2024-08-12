#!/usr/bin/env bash

# Function to generate Zsh completion script
generate_completion_script() {
  local command_help_output="$1"
  local command_name="$2"

  # Extract commands and options from help output
  local commands
  commands=$(echo "$command_help_output" | grep -Eo '^\s{2,}[a-zA-Z0-9_-]+' | sed 's/^\s\+//')
  local options
  options=$(echo "$command_help_output" | grep -Eo '^\s{2,}--?[a-zA-Z0-9_-]+' | sed 's/^\s\+//')

  # Format commands and options for Zsh completion script
  local formatted_commands
  formatted_commands=$(echo "$commands" | sed 's/^/"/;s/$/" \\/')
  local formatted_options
  formatted_options=$(echo "$options" | sed 's/^/"/;s/$/" \\/')

  # Generate Zsh completion script using the template
  local completion_script
  completion_script=$(cat <<EOF
#compdef _${command_name} ${command_name}

_${command_name}() {
  local -a commands
  local -a options

  commands=(
    ${formatted_commands}
  )

  options=(
    ${formatted_options}
  )

  _arguments -s \$options
}

_${command_name}
EOF
  )

  echo "$completion_script"
}

# Main script logic
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <command>"
  exit 1
fi

command="$1"

# Get help output from the command
command_help_output=$($command)

# Extract command name from the command string
command_name=$(echo "$command" | awk '{print $1}')

# Generate completion script
completion_script=$(generate_completion_script "$command_help_output" "$command_name")

# Output the completion script
echo "$completion_script"