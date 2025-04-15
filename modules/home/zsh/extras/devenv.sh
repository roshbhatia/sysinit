#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# sysinit.nix-shell::ignore
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
  echo "  devenv.nix.shell [args]    - Run nix-shell with devenv.shell.nix"
  echo "  devenv.init                - Initialize a new devenv.shell.nix in the current directory"
  echo "  devenv.nix.shell --help    - Show this help message"
  echo 
  echo "This function looks for a 'devenv.shell.nix' file in the current"
  echo "directory and runs nix-shell with it. All arguments are passed"
  echo "directly to nix-shell."
}

# Function for nix-shell with explicit devenv.shell.nix file
function devenv.nix.shell() {
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
  
  # We want to run nushell inside the nix-shell environment
  # Using --command nu is more reliable than --run nu
  if command -v nu &> /dev/null; then
    log_debug "Using nushell for interactive shell"
    nix-shell "$shell_file" --command "nu" "$@"
  else
    log_debug "Nushell not found, using default shell"
    nix-shell "$shell_file" "$@"
  fi
  exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    log_success "nix-shell completed successfully" file="$shell_file"
  else
    log_error "nix-shell exited with error" file="$shell_file" exit_code="$exit_code"
  fi
  
  return $exit_code
}

# Initialize a new devenv.shell.nix in the current directory
function devenv.init() {
  local shell_file="devenv.shell.nix"
  local base_template="/Users/rshnbhatia/github/roshbhatia/sysinit/development/ephemeral-shells/base.devenv.shell.nix"
  
  # Check if file already exists
  if [[ -f "$shell_file" ]]; then
    log_error "Shell file already exists" file="$shell_file" pwd="$(pwd)"
    echo "Error: $shell_file already exists in the current directory."
    echo "Use a different name or remove the existing file before initializing a new one."
    return 1
  fi
  
  # Check if base template exists
  if [[ ! -f "$base_template" ]]; then
    log_error "Base template not found" file="$base_template"
    echo "Error: Base template not found at $base_template"
    return 1
  fi
  
  # Copy the base template to the current directory
  log_info "Initializing devenv.shell.nix from template" template="$base_template"
  cp "$base_template" "$shell_file"
  exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    log_success "devenv.shell.nix initialized successfully"
    echo "✅ Created $shell_file in $(pwd)"
    echo "You can now run 'devenv.nix.shell' to enter the environment"
    return 0
  else
    log_error "Failed to initialize devenv.shell.nix" exit_code="$exit_code"
    echo "Error: Failed to create $shell_file"
    return 1
  fi
}

# Auto-load function - automatically run devenv.nix.shell when entering a directory with devenv.shell.nix
_devenv_autoload() {
  local shell_file="devenv.shell.nix"
  
  # Check if we're in a real terminal and if the file exists
  if [[ -t 1 && -f "$shell_file" ]]; then
    log_debug "Found devenv.shell.nix in $(pwd), auto-loading environment"
    devenv.nix.shell
  fi
}

# Only set up hooks when running in zsh
if [[ -n "$ZSH_VERSION" ]]; then
  # Register the chpwd hook to check for devenv.shell.nix when changing directories
  typeset -ga chpwd_functions
  if [[ -z "${chpwd_functions[(r)_devenv_autoload]}" ]]; then
    chpwd_functions+=(_devenv_autoload)
  fi
fi

# Display help when called without arguments from the command line
if [[ $# -eq 0 && "${BASH_SOURCE[0]}" == "${0}" ]]; then
  devenv.nix.shell --help
fi