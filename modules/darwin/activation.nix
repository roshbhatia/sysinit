{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../lib/activation-utils.nix { inherit lib; };
in {
  imports = [];
  
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
      log_info "Setting up sysinit symlink"
      
      SYSINIT_SRC="$HOME/github/personal/roshbhatia/sysinit"
      SYSINIT_DEST="$HOME/.config/sysinit"
      
      if [ -d "$SYSINIT_SRC" ]; then
        if [ ! -L "$SYSINIT_DEST" ] || [ "$(readlink "$SYSINIT_DEST")" != "$SYSINIT_SRC" ]; then
          log_command "mkdir -p $(dirname "$SYSINIT_DEST")" "Creating parent directory"
          log_command "ln -sfn "$SYSINIT_SRC" "$SYSINIT_DEST"" "Creating symlink"
          log_success "Sysinit symlink created: $SYSINIT_DEST -> $SYSINIT_SRC"
        else
          log_info "Sysinit symlink already exists and is correct"
        fi
      else
        log_error "Sysinit source directory not found: $SYSINIT_SRC"
      fi
    '';
  };
}
