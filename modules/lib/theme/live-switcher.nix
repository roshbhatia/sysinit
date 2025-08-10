{
  lib,
  pkgs,
  config,
  values,
  ...
}:

with lib;

let
  themeStateDir = "${config.home.homeDirectory}/.local/state/sysinit/themes";
  themes = import ./default.nix { inherit lib; };

  allThemeCombinations = flatten (
    mapAttrsToList (
      colorscheme: themeData:
      map (variant: {
        name = "${colorscheme}-${variant}";
        colorscheme = colorscheme;
        variant = variant;
      }) themeData.meta.variants
    ) themes.themes
  );

  theme-manager = pkgs.writeShellScriptBin "theme-manager" ''
    #!/usr/bin/env bash

    THEME_STATE_DIR="${themeStateDir}"
    CURRENT_THEME_FILE="$THEME_STATE_DIR/current-theme.json"

    mkdir -p "$THEME_STATE_DIR"

    # Initialize current theme if it doesn't exist
    if [ ! -f "$CURRENT_THEME_FILE" ]; then
      echo '${
        builtins.toJSON {
          colorscheme = values.theme.colorscheme;
          variant = values.theme.variant;
          timestamp = "$(date -Iseconds)";
        }
      }' > "$CURRENT_THEME_FILE"
    fi

    echo "Theme manager started, watching for changes..."

    # Watch for theme changes
    while true; do
      if command -v fswatch >/dev/null 2>&1; then
        fswatch -o "$CURRENT_THEME_FILE" | while read event; do
          echo "Theme change detected, reloading applications..."
          ${reload-theme-configs}/bin/reload-theme-configs
        done
      else
        # Fallback: poll for changes every 2 seconds
        LAST_MOD=""
        while true; do
          if [ -f "$CURRENT_THEME_FILE" ]; then
            CURRENT_MOD=$(stat -f %m "$CURRENT_THEME_FILE" 2>/dev/null || stat -c %Y "$CURRENT_THEME_FILE")
            if [ "$CURRENT_MOD" != "$LAST_MOD" ]; then
              if [ -n "$LAST_MOD" ]; then
                echo "Theme change detected, reloading applications..."
                ${reload-theme-configs}/bin/reload-theme-configs
              fi
              LAST_MOD="$CURRENT_MOD"
            fi
          fi
          sleep 2
        done
      fi
      sleep 5
    done
  '';

  reload-theme-configs = pkgs.writeShellScriptBin "reload-theme-configs" ''
        #!/usr/bin/env bash

        THEME_STATE_DIR="${themeStateDir}"
        CURRENT_THEME_FILE="$THEME_STATE_DIR/current-theme.json"

        if [ ! -f "$CURRENT_THEME_FILE" ]; then
          echo "No theme configuration found"
          exit 1
        fi

        THEME_INFO=$(cat "$CURRENT_THEME_FILE")
        COLORSCHEME=$(echo "$THEME_INFO" | ${pkgs.jq}/bin/jq -r '.colorscheme')
        VARIANT=$(echo "$THEME_INFO" | ${pkgs.jq}/bin/jq -r '.variant')

        echo "Switching to theme: $COLORSCHEME-$VARIANT"

        # Reload WezTerm configuration
        if pgrep -x "wezterm-gui" > /dev/null; then
          echo "Reloading WezTerm configuration..."
          # WezTerm will automatically reload when config files change
          touch ~/.config/wezterm/wezterm.lua
        fi

        # Update Neovim theme for any running instances
        if pgrep -x "nvim" > /dev/null; then
          echo "Updating Neovim theme..."
          # Send command to running Neovim instances via remote
          for sock in /tmp/nvim*/0; do
            if [ -S "$sock" ]; then
              ${pkgs.neovim}/bin/nvim --server "$sock" --remote-send ":lua require('sysinit.theme.live-switcher').apply_current_theme()<CR>" 2>/dev/null || true
            fi
          done
        fi

        # Update bat theme
        echo "Updating bat configuration..."
        mkdir -p ~/.config/bat
        cat > ~/.config/bat/config <<EOF
    --theme="$COLORSCHEME-$VARIANT"
    --style=numbers,changes,header
    --pager="less -FR"
    EOF

        # Rebuild bat cache if bat is available
        if command -v ${pkgs.bat}/bin/bat >/dev/null 2>&1; then
          ${pkgs.bat}/bin/bat cache --build 2>/dev/null || true
        fi

        # Update terminal colors using OSC sequences
        if [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
          echo "Updating terminal colors..."
          ${update-terminal-colors}/bin/update-terminal-colors "$COLORSCHEME" "$VARIANT"
        fi

        echo "Theme switch complete: $COLORSCHEME-$VARIANT"
  '';

  update-terminal-colors = pkgs.writeShellScriptBin "update-terminal-colors" ''
    #!/usr/bin/env bash

    COLORSCHEME="$1"
    VARIANT="$2"

    if [ -z "$COLORSCHEME" ] || [ -z "$VARIANT" ]; then
      echo "Usage: update-terminal-colors <colorscheme> <variant>"
      exit 1
    fi

    # Get theme colors from the cache
    THEME_CACHE_DIR="${themeStateDir}/theme-cache"
    THEME_CONFIG="$THEME_CACHE_DIR/$COLORSCHEME-$VARIANT/config.json"

    if [ ! -f "$THEME_CONFIG" ]; then
      echo "Theme config not found: $THEME_CONFIG"
      return 1
    fi

    # Extract colors using jq
    FG=$(${pkgs.jq}/bin/jq -r '.palette.text // .palette.foreground // "#ffffff"' "$THEME_CONFIG")
    BG=$(${pkgs.jq}/bin/jq -r '.palette.base // .palette.background // "#000000"' "$THEME_CONFIG")

    # Send OSC sequences to update terminal colors
    printf '\033]10;%s\007' "$FG"  # foreground
    printf '\033]11;%s\007' "$BG"  # background
    printf '\033]12;%s\007' "$FG"  # cursor

    # Update LS_COLORS if vivid is available
    if command -v ${pkgs.vivid}/bin/vivid >/dev/null 2>&1; then
      VIVID_THEME=$(${pkgs.jq}/bin/jq -r '.vividTheme // "molokai"' "$THEME_CONFIG")
      export LS_COLORS=$(${pkgs.vivid}/bin/vivid generate "$VIVID_THEME" 2>/dev/null || echo "")
      echo "export LS_COLORS='$LS_COLORS'" > ~/.local/state/sysinit/themes/ls_colors
    fi
  '';

  sysinit-theme = pkgs.writeShellScriptBin "sysinit-theme" ''
        #!/usr/bin/env bash

        THEME_STATE_DIR="${themeStateDir}"
        CURRENT_THEME_FILE="$THEME_STATE_DIR/current-theme.json"
        CACHE_DIR="$THEME_STATE_DIR/theme-cache"

        # Available themes (auto-discovered from theme library)
        discover_themes() {
          echo "${concatStringsSep "\n" (map (t: t.name) allThemeCombinations)}"
        }

        # Show current theme
        show_current() {
          if [ -f "$CURRENT_THEME_FILE" ]; then
            local current=$(cat "$CURRENT_THEME_FILE" | ${pkgs.jq}/bin/jq -r '.colorscheme + "-" + .variant')
            echo "Current theme: $current"
          else
            echo "No theme set"
          fi
        }

        # List available themes
        list_themes() {
          echo "Available themes:"
          local current=""
          if [ -f "$CURRENT_THEME_FILE" ]; then
            current=$(cat "$CURRENT_THEME_FILE" 2>/dev/null | ${pkgs.jq}/bin/jq -r '.colorscheme + "-" + .variant')
          fi

          discover_themes | while read theme; do
            if [ "$theme" = "$current" ]; then
              echo "  * $theme (current)"
            else
              echo "    $theme"
            fi
          done
        }

        # Switch to theme
        switch_theme() {
          local theme_name="$1"
          local colorscheme="''${theme_name%-*}"
          local variant="''${theme_name#*-}"

          # Validate theme exists
          if ! discover_themes | grep -q "^$theme_name$"; then
            echo "Error: Theme '$theme_name' not found"
            echo "Available themes:"
            discover_themes | sed 's/^/  /'
            exit 1
          fi

          echo "Switching to theme: $theme_name"

          mkdir -p "$THEME_STATE_DIR"

          # Update current theme
          cat > "$CURRENT_THEME_FILE" <<EOF
    {
      "colorscheme": "$colorscheme",
      "variant": "$variant",
      "timestamp": "$(date -Iseconds)"
    }
    EOF

          echo "Theme switched to $theme_name"
          echo "Applications will update automatically"
        }

        # Preview theme (temporary switch with revert option)
        preview_theme() {
          local theme_name="$1"
          local backup_file="$THEME_STATE_DIR/theme-backup.json"

          # Backup current theme
          if [ -f "$CURRENT_THEME_FILE" ]; then
            cp "$CURRENT_THEME_FILE" "$backup_file"
          fi

          echo "Previewing theme: $theme_name (Ctrl+C to revert)"
          switch_theme "$theme_name"

          # Set up signal handler for revert
          trap 'restore_theme; exit 0' INT TERM

          echo "Press Enter to apply permanently, or Ctrl+C to revert..."
          read -r
          echo "Theme applied permanently"
          rm -f "$backup_file"
        }

        # Restore from backup
        restore_theme() {
          local backup_file="$THEME_STATE_DIR/theme-backup.json"
          if [ -f "$backup_file" ]; then
            mv "$backup_file" "$CURRENT_THEME_FILE"
            echo "Theme reverted to previous setting"
          else
            echo "No backup found"
          fi
        }

        # Main command handler
        case "$1" in
          "current")
            show_current
            ;;
          "list")
            list_themes
            ;;
          "switch")
            if [ -z "$2" ]; then
              echo "Usage: sysinit-theme switch <theme-name>"
              exit 1
            fi
            switch_theme "$2"
            ;;
          "preview")
            if [ -z "$2" ]; then
              echo "Usage: sysinit-theme preview <theme-name>"
              exit 1
            fi
            preview_theme "$2"
            ;;
          "reload")
            ${reload-theme-configs}/bin/reload-theme-configs
            ;;
          *)
            echo "Usage: sysinit-theme {current|list|switch|preview|reload} [theme-name]"
            echo ""
            echo "Commands:"
            echo "  current          Show current active theme"
            echo "  list            List all available themes"
            echo "  switch <theme>  Switch to theme permanently"
            echo "  preview <theme> Preview theme temporarily"
            echo "  reload          Reload current theme configuration"
            exit 1
            ;;
        esac
  '';

in
{
  home.packages = [
    theme-manager
    reload-theme-configs
    update-terminal-colors
    sysinit-theme
    pkgs.jq
    pkgs.fswatch
  ];

  # Create theme state directory and cache
  home.activation.createThemeState = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    echo "Setting up live theme switching..."

    mkdir -p ${themeStateDir}/{theme-cache,application-configs,hooks}

    # Initialize current theme if not exists
    if [ ! -f ${themeStateDir}/current-theme.json ]; then
      echo '${
        builtins.toJSON {
          colorscheme = values.theme.colorscheme;
          variant = values.theme.variant;
          timestamp = "$(date -Iseconds)";
        }
      }' > ${themeStateDir}/current-theme.json
    fi

    # Build theme cache for all available themes
    ${lib.concatMapStringsSep "\n" (theme: ''
            THEME_DIR="${themeStateDir}/theme-cache/${theme.name}"
            mkdir -p "$THEME_DIR"

            # Generate theme configuration
            cat > "$THEME_DIR/config.json" <<'EOF'
      ${builtins.toJSON {
        colorscheme = theme.colorscheme;
        variant = theme.variant;
        palette = themes.getThemePalette theme.colorscheme theme.variant;
        semanticColors = themes.getSemanticColors theme.colorscheme theme.variant;
        appThemes =
          let
            rawNeovimTheme = themes.getAppTheme "neovim" theme.colorscheme theme.variant;
          in
          {
            wezterm = themes.getAppTheme "wezterm" theme.colorscheme theme.variant;
            neovim =
              if
                builtins.isAttrs rawNeovimTheme
                && builtins.hasAttr "colorscheme" rawNeovimTheme
                && builtins.isFunction rawNeovimTheme.colorscheme
              then
                rawNeovimTheme
                // {
                  colorscheme = rawNeovimTheme.colorscheme theme.variant;
                }
              else
                rawNeovimTheme;
            bat = themes.getAppTheme "bat" theme.colorscheme theme.variant;
            vivid = themes.getAppTheme "vivid" theme.colorscheme theme.variant;
          };
        vividTheme = themes.getAppTheme "vivid" theme.colorscheme theme.variant;
      }}
      EOF
    '') allThemeCombinations}

    echo "Theme cache built successfully"
  '';

  # Theme management can be started manually with: theme-manager
  # Or via: launchctl load ~/Library/LaunchAgents/com.sysinit.theme-manager.plist
  home.file."Library/LaunchAgents/com.sysinit.theme-manager.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>com.sysinit.theme-manager</string>
      <key>ProgramArguments</key>
      <array>
        <string>${theme-manager}/bin/theme-manager</string>
      </array>
      <key>RunAtLoad</key>
      <false/>
      <key>KeepAlive</key>
      <false/>
      <key>StandardOutPath</key>
      <string>${themeStateDir}/theme-manager.log</string>
      <key>StandardErrorPath</key>
      <string>${themeStateDir}/theme-manager.log</string>
      <key>EnvironmentVariables</key>
      <dict>
        <key>PATH</key>
        <string>${
          lib.makeBinPath [
            pkgs.jq
            pkgs.fswatch
          ]
        }</string>
      </dict>
    </dict>
    </plist>
  '';

  # Shell aliases for easy access
  programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
    "theme" = "sysinit-theme";
    "theme-current" = "sysinit-theme current";
    "theme-list" = "sysinit-theme list";
  };

  programs.nushell.shellAliases = mkIf config.programs.nushell.enable {
    "theme" = "sysinit-theme";
    "theme-current" = "sysinit-theme current";
    "theme-list" = "sysinit-theme list";
  };

  # Source LS_COLORS in shells
  programs.zsh.initExtra = mkIf config.programs.zsh.enable ''
    # Load dynamic LS_COLORS from theme switcher
    if [ -f ~/.local/state/sysinit/themes/ls_colors ]; then
      source ~/.local/state/sysinit/themes/ls_colors
    fi
  '';

  programs.nushell.extraEnv = mkIf config.programs.nushell.enable ''
    # Load dynamic LS_COLORS from theme switcher
    if ("~/.local/state/sysinit/themes/ls_colors" | path exists) {
      source ~/.local/state/sysinit/themes/ls_colors
    }
  '';
}
