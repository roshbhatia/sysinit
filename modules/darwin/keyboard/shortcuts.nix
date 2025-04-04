# Keyboard shortcuts configuration for macOS
{ config, lib, pkgs, ... }:

{
  # System keyboard shortcuts using nix-darwin
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;  # Remap Caps Lock to Control
  };

  # Configure keyboard-related global domain settings
  system.defaults.NSGlobalDomain = {
    # Keyboard navigation
    AppleKeyboardUIMode = 3;  # Full keyboard access for all controls
    
    # Text behavior - disable auto-corrections
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    
    # Note: KeyRepeat and InitialKeyRepeat are already defined in system.nix
  };

  # Configure custom keyboard shortcuts
  system.defaults.symbolichotkeys.enable = true;
  system.defaults.symbolichotkeys.AppleSymbolicHotKeys = {
    # Modifier keys mapping:
    # 1048576 = Command (⌘)
    # 131072 = Shift (⇧)
    # 262144 = Control (⌃)
    # 524288 = Option (⌥)
    # Combined: Command+Shift = 1179648
    
    # Key shortcuts you use
    
    # Spotlight: Command+Space (default)
    64 = {
      enabled = true;
      value = {
        parameters = [ 32 49 1048576 ];
        type = "standard";
      };
    };
    
    # Screenshots
    
    # Screenshot (entire screen): Command+Shift+3
    28 = {
      enabled = true;
      value = {
        parameters = [ 51 20 1179648 ];
        type = "standard";
      };
    };
    
    # Screenshot (selection): Command+Shift+4
    29 = {
      enabled = true;
      value = {
        parameters = [ 52 21 1179648 ];
        type = "standard";
      };
    };
    
    # App Switching
    
    # Command-Tab: Move focus to next application (default)
    35 = {
      enabled = true;
      value = {
        parameters = [ 48 48 1048576 ];
        type = "standard";
      };
    };
    
    # Command-Shift-Tab: Move focus to previous application
    37 = {
      enabled = true;
      value = { 
        parameters = [ 48 48 1179648 ];
        type = "standard";
      };
    };
  };
  
  # Add an activation script to configure some shortcuts that nix-darwin can't handle directly
  system.activationScripts.postUserActivation.text = lib.mkAfter ''
    # Configure keyboard shortcuts not available through nix-darwin
    echo "Configuring additional keyboard shortcuts..."
    
    # Configure function keys to behave as standard function keys (F1, F2, etc.)
    # Instead of media keys
    defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
    
    # Disable automatic period insertion on double-space
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    
    # Apply changes
    echo "Keyboard shortcuts configured."
  '';
}