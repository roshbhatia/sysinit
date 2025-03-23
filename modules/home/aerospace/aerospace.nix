{ config, lib, pkgs, ... }:

let
  settings = {
    # Place a copy of this config to ~/.aerospace.toml
    # After that, you can edit ~/.aerospace.toml to your liking
    
    # You can use it to add commands that run after login to macOS user session.
    # 'start-at-login' needs to be 'true' for 'after-login-command' to work
    # Available commands: https://nikitabobko.github.io/AeroSpace/commands
    after-login-command = [];
    
    # You can use it to add commands that run after AeroSpace startup.
    # 'after-startup-command' is run after 'after-login-command'
    # Available commands : https://nikitabobko.github.io/AeroSpace/commands
    after-startup-command = [];
    
    # Start AeroSpace at login
    start-at-login = true;
    
    # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
    enable-normalization-flatten-containers = true;
    enable-normalization-opposite-orientation-for-nested-containers = true;
    
    # See: https://nikitabobko.github.io/AeroSpace/guide#layouts
    # The 'accordion-padding' specifies the size of accordion padding
    # You can set 0 to disable the padding feature
    accordion-padding = 30;
    
    # Possible values: tiles|accordion
    default-root-container-layout = "tiles";
    
    # Possible values: horizontal|vertical|auto
    # 'auto' means: wide monitor (anything wider than high) gets horizontal orientation,
    #               tall monitor (anything higher than wide) gets vertical orientation
    default-root-container-orientation = "auto";
    
    # Mouse follows focus when focused monitor changes
    # Drop it from your config, if you don't like this behavior
    # See https://nikitabobko.github.io/AeroSpace/guide#on-focus-changed-callbacks
    # See https://nikitabobko.github.io/AeroSpace/commands#move-mouse
    # Fallback value (if you omit the key): on-focused-monitor-changed = []
    on-focused-monitor-changed = ["move-mouse monitor-lazy-center"];
    
    # You can effectively turn off macOS "Hide application" (cmd-h) feature by toggling this flag
    # Useful if you don't use this macOS feature, but accidentally hit cmd-h or cmd-alt-h key
    # Also see: https://nikitabobko.github.io/AeroSpace/goodies#disable-hide-app
    automatically-unhide-macos-hidden-apps = false;
    
    # Possible values: (qwerty|dvorak)
    # See https://nikitabobko.github.io/AeroSpace/guide#key-mapping
    key-mapping = {
      preset = "qwerty";
    };
    
    # Gaps between windows (inner-*) and between monitor edges (outer-*)
    gaps = {
      inner = {
        horizontal = 0;
        vertical = 0;
      };
      outer = {
        left = 0;
        bottom = 0;
        top = 0;
        right = 0;
      };
    };
    
    # Main binding mode declaration
    # See: https://nikitabobko.github.io/AeroSpace/guide#binding-modes
    # 'main' binding mode must be always presented
    mode = {
      main = {
        binding = {
          # All possible keys:
          # - Letters.        a, b, c, ..., z
          # - Numbers.        0, 1, 2, ..., 9
          # - Keypad numbers. keypad0, keypad1, keypad2, ..., keypad9
          # - F-keys.         f1, f2, ..., f20
          # - Special keys.   minus, equal, period, comma, slash, backslash, quote, semicolon,
          #                   backtick, leftSquareBracket, rightSquareBracket, space, enter, esc,
          #                   backspace, tab
          # - Keypad special. keypadClear, keypadDecimalMark, keypadDivide, keypadEnter, keypadEqual,
          #                   keypadMinus, keypadMultiply, keypadPlus
          # - Arrows.         left, down, up, right
          
          # Use cmd key to not conflict with spectacle
          "cmd-slash" = "layout tiles horizontal vertical";
          "cmd-comma" = "layout accordion horizontal vertical";
          
          # Focus commands
          "cmd-h" = "focus left";
          "cmd-j" = "focus down";
          "cmd-k" = "focus up";
          "cmd-l" = "focus right";
          
          # Move commands
          "cmd-shift-h" = "move left";
          "cmd-shift-j" = "move down";
          "cmd-shift-k" = "move up";
          "cmd-shift-l" = "move right";
          
          # Resize commands (work alongside Spectacle's cmd-alt-arrow)
          "cmd-minus" = "resize smart -50";
          "cmd-equal" = "resize smart +50";
          
          # Workspace commands
          "cmd-1" = "workspace 1";
          "cmd-2" = "workspace 2";
          "cmd-3" = "workspace 3";
          "cmd-4" = "workspace 4";
          "cmd-5" = "workspace 5";
          "cmd-6" = "workspace 6";
          "cmd-7" = "workspace 7";
          "cmd-8" = "workspace 8";
          "cmd-9" = "workspace 9";
          
          # Move to workspace commands
          "cmd-shift-1" = "move-node-to-workspace 1";
          "cmd-shift-2" = "move-node-to-workspace 2";
          "cmd-shift-3" = "move-node-to-workspace 3";
          "cmd-shift-4" = "move-node-to-workspace 4";
          "cmd-shift-5" = "move-node-to-workspace 5";
          "cmd-shift-6" = "move-node-to-workspace 6";
          "cmd-shift-7" = "move-node-to-workspace 7";
          "cmd-shift-8" = "move-node-to-workspace 8";
          "cmd-shift-9" = "move-node-to-workspace 9";
          
          # Switch between workspaces
          "cmd-tab" = "workspace-back-and-forth";
          "cmd-shift-tab" = "move-workspace-to-monitor --wrap-around next";
          
          # Service mode
          "cmd-shift-semicolon" = "mode service";
        };
      };
      
      # 'service' binding mode declaration
      service = {
        binding = {
          "esc" = ["reload-config", "mode main"];
          "r" = ["flatten-workspace-tree", "mode main"]; # reset layout
          "f" = ["layout floating tiling", "mode main"]; # Toggle between floating and tiling layout
          "backspace" = ["close-all-windows-but-current", "mode main"];
          
          "cmd-shift-h" = ["join-with left", "mode main"];
          "cmd-shift-j" = ["join-with down", "mode main"];
          "cmd-shift-k" = ["join-with up", "mode main"];
          "cmd-shift-l" = ["join-with right", "mode main"];
          
          "down" = "volume down";
          "up" = "volume up";
          "shift-down" = ["volume set 0", "mode main"];
        };
      };
    };
  };
  # Convert settings to TOML
  tomlFormat = pkgs.formats.toml {};
  configFile = tomlFormat.generate "aerospace.toml" settings;
in
{
  home.file.".aerospace.toml".source = configFile;
}
