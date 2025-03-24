# devenv.pre.nu - A direnv-like nushell plugin for devenv.nix.shell
# This module provides automatic loading of devenv.shell.nix environments

# Store our active environment info
$env.DEVENV_ACTIVE_PATH = ""
$env.DEVENV_NIX_SHELL = false

# Define the hook to run when changing directories
def create_left_prompt [] {
    # Get environment variables like PWD and DEVENV_ACTIVE_PATH
    let pwd = ($env.PWD | str replace $env.HOME "~")
    
    # Call our devenv check hook
    check_devenv_shell $pwd
    
    # Generate prompt display (you can customize this)
    if ($env.DEVENV_NIX_SHELL) {
        # Show special prompt when in a devenv environment
        $"(ansi green)nix-shell(ansi reset):(ansi cyan)($pwd)(ansi reset)> "
    } else {
        # Regular prompt
        $"(ansi cyan)($pwd)(ansi reset)> "
    }
}

# Function to check for devenv.shell.nix files
def check_devenv_shell [pwd: string] {
    # Check if we already have an active environment
    let active_path = ($env | get -i DEVENV_ACTIVE_PATH | default "")
    
    # If active_path is set, check if current path is a subfolder
    if ($active_path != "") and ($pwd | str starts-with $active_path) {
        # We're in a subfolder of an active environment, keep it active
        return
    }
    
    # Check if we moved to a parent directory of an active environment
    if ($active_path != "") and ($active_path | str starts-with $pwd) {
        # We moved up out of an active environment
        print $"(ansi yellow)Exiting devenv.nix.shell environment from ($active_path)(ansi reset)"
        $env.DEVENV_ACTIVE_PATH = ""
        $env.DEVENV_NIX_SHELL = false
        return
    }
    
    # Check if the current directory has a devenv.shell.nix file
    if (ls | where name == "devenv.shell.nix" | length) > 0 {
        # If we're not already in a devenv shell, activate it
        # If DEVENV_NIX_SHELL is true, we're already in a shell and should do nothing
    } else {
        # No devenv.shell.nix in current directory, and not a parent of active environment
        # (parent case is handled above)
        if ($active_path != "") {
            # We had an active path but moved to an unrelated directory
            print $"(ansi yellow)Exiting devenv.nix.shell environment from ($active_path)(ansi reset)"
            $env.DEVENV_ACTIVE_PATH = ""
            $env.DEVENV_NIX_SHELL = false
        }
    }
}

# Set up the hook to activate on directory change
$env.config = ($env.config | upsert hooks.env_change.PWD {
    let pwd = $env.PWD
    check_devenv_shell $pwd
})

# Set up the prompt to show active status
$env.config = ($env.config | upsert prompt (create_left_prompt))

print "✅ Loaded devenv.nix.shell autoloader for Nushell"