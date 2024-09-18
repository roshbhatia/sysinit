#!/usr/bin/env zsh
# shellcheck disable=all

set -e

# Function to generate Zsh completion script
generate_smart_completion_script() {
  local command="$1"
  local output="$2"
  local output_path="$3"
  local template=$(cat <<'EOF'
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

  _arguments -s $options
}

_${command_name}
EOF
  )

  local prompt=$(cat <<EOF
You are a senior SRE who is very experienced in shell scripting.
Generate a Zsh completion script for this command's help output
(manually specified with the --help or -h or something similar),
paying attention to the description in the help output.

VERY IMPORTANT. The completion script should be as smart as possible!!!
This includes adding descriptions to the options, and grouping them.
You should also add support for common aliases if relevant -- for ex; kubectl is often aliased to k.
Or, terraform is often aliased to tf.

It is also VERY IMPORTANT that the syntax be correct. 
Remember to generate a CUSTOM COMPLETION SCRIPT using the template,
and not provide a completion function that may be present in the command.

Command: $command

Literal output of the help command: $output

Template:
$template
EOF
  )
  
  # Run the mods command and capture the output
  local mods_output
  mods_output=$(mods --role shell "$prompt")

  # Create a temporary file to hold the mods output
  local temp_file
  temp_file=$(mktemp)

  # Write the mods output to the temporary file
  echo "$mods_output" > "$temp_file"

  # Open the temporary file in the editor defined by $EDITOR
  ${EDITOR:-vi} "$temp_file"

  # Save the edited content to the specified output path
  mv "$temp_file" "$output_path"
}

# Function to list all completion scripts
list_completions() {
  local completion_dir="$HOME/.completions"
  if [ -d "$completion_dir" ]; then
    echo "Completion scripts in $completion_dir:"
    ls "$completion_dir"
  else
    echo "No completions directory found at $completion_dir"
  fi
}

# Error handling function
handle_error() {
  echo "An error occurred. Please check the command and try again."
  exit 1
}

# Trap errors and call the error handling function
trap 'handle_error' ERR

# Main script logic
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)
        list_completions
        exit 0
        ;;
      *)
        command="$1"
        shift
        break
        ;;
    esac
  done

  if [[ -z "$command" ]]; then
    echo "Usage: $0 [--list] <command> [command options]"
    exit 1
  fi

  # Capture the remaining arguments as the command to run
  command_to_run="$command $*"

  # Get help output from the command
  command_help_output=$(eval "$command_to_run")

  # Ensure the completions directory exists
  mkdir -p "$HOME/.completions"

  # Extract command name from the command string
  command_name=$(echo "$command" | awk '{print $1}')

  # Generate completion script
  generate_smart_completion_script "$command_to_run" "$command_help_output" "$HOME/.completions/${command_name}_completion.zsh"

  echo "Completion script saved to $HOME/.completions/${command_name}_completion.zsh"
}

# Call the main function
main "$@"