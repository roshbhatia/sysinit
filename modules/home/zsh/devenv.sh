#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

#       888                                               
#       888                                               
#       888                                               
#   .d88888 .d88b. 888  888 .d88b. 88888b. 888  888      
#  d88" 888d8P  Y8b888  888d8P  Y8b888 "88b888  888      
#  888  888888888888Y88  88P88888888888  888888  888      
#  Y88b 888Y8b.     Y8bd8P Y8b.    888  888Y88b 888      
#   "Y88888 "Y8888   Y88P   "Y8888 888  888 "Y88888      
#                                             888      
#                                        Y8b d88P      
#                                         "Y88P"

# Ensure logging library is loaded
[ -f "$HOME/.config/zsh/loglib.sh" ] && source "$HOME/.config/zsh/loglib.sh"

# Helper function for showing devenv help
devenv_help() {
  echo "                                              "
  echo "      888                                               "
  echo "      888                                               "
  echo "      888                                               "
  echo "  .d88888 .d88b. 888  888 .d88b. 88888b. 888  888      "
  echo " d88\" 888d8P  Y8b888  888d8P  Y8b888 \"88b888  888      "
  echo " 888  888888888888Y88  88P88888888888  888888  888      "
  echo " Y88b 888Y8b.     Y8bd8P Y8b.    888  888Y88b 888      "
  echo "  \"Y88888 \"Y8888   Y88P   \"Y8888 888  888 \"Y88888      "
  echo "                                            888      "
  echo "                                       Y8b d88P      "
  echo "                                        \"Y88P\"       "
  echo
  echo "Development Environment Commands:"
  echo "  devenv.nix-shell [args]    - Run nix-shell with devenv.shell.nix"
  echo "  devenv.nix-shell --help    - Show this help message"
  echo 
  echo "This function looks for a 'devenv.shell.nix' file in the current"
  echo "directory and runs nix-shell with it. All arguments are passed"
  echo "directly to nix-shell."
}

# Function for nix-shell with explicit devenv.shell.nix file
function devenv.nix-shell() {
  local shell_file="devenv.shell.nix"
  
  # Parse arguments
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    log_debug "Showing help message"
    devenv_help
    return 0
  fi

  # Check if devenv.shell.nix exists
  log_debug "Checking for devenv.shell.nix" pwd="$(pwd)"
  if [[ ! -f "$shell_file" ]]; then
    log_error "Shell file not found" file="$shell_file" pwd="$(pwd)"
    echo "Error: $shell_file not found in the current directory."
    return 1
  fi
  
  # Run nix-shell with the specified file and pass all arguments
  log_info "Running nix-shell with devenv file" file="$shell_file" args="$*"
  nix-shell "$shell_file" "$@"
  exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    log_success "nix-shell completed successfully" file="$shell_file"
  else
    log_error "nix-shell exited with error" file="$shell_file" exit_code="$exit_code"
  fi
  
  return $exit_code
}

# Display help when called without arguments from the command line
if [[ $# -eq 0 && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  devenv.nix-shell --help
fi