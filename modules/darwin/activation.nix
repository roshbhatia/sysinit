{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../lib/activation-utils.nix { inherit lib; };
in {
  imports = [];
  
  # Set environment variables needed by activation scripts
  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
  };
  
  # Set up the activation utilities with additional paths from user config
  home.activation.setupActivationUtils = activationUtils.mkActivationUtils {
    logDir = "/tmp/sysinit-logs";
    logPrefix = "sysinit";
    additionalPaths = if userConfig ? additionalPaths then userConfig.additionalPaths else [];
  };
  
  # Example of a custom activation script using the utilities
  # This creates a symlink from your home directory to your sysinit config
  home.activation.sysinitSymlink = {
    after = [ "setupActivationUtils" ];
    before = [];
    data = ''
      # Source the activation tools
      source ${../lib/activation-tools.sh}
      
      log_info "Setting up sysinit symlink"
      
      SYSINIT_SRC="$HOME/github/personal/roshbhatia/sysinit"
      SYSINIT_DEST="$HOME/.config/sysinit"
      
      if [ -d "$SYSINIT_SRC" ]; then
        # Check if symlink exists
        if [ ! -L "$SYSINIT_DEST" ]; then
          # Symlink doesn't exist, create it
          log_command "mkdir -p $(dirname "$SYSINIT_DEST")" "Creating parent directory"
          log_command "ln -sfn "$SYSINIT_SRC" "$SYSINIT_DEST"" "Creating symlink"
          log_success "Sysinit symlink created: $SYSINIT_DEST -> $SYSINIT_SRC"
        else
          # Check where the symlink points
          CURRENT_TARGET=$(readlink "$SYSINIT_DEST")
          if [ "$CURRENT_TARGET" = "$SYSINIT_SRC" ]; then
            log_info "Sysinit symlink already exists and is correct"
          else
            log_info "Updating existing symlink to point to the correct location"
            log_command "ln -sfn "$SYSINIT_SRC" "$SYSINIT_DEST"" "Updating symlink"
            log_success "Sysinit symlink updated: $SYSINIT_DEST -> $SYSINIT_SRC"
          fi
        fi
      else
        log_error "Sysinit source directory not found: $SYSINIT_SRC"
      fi
    '';
  };
}
