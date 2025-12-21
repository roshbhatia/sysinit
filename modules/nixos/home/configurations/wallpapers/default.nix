{
  pkgs,
  ...
}:

{
  # Wallpaper management: scripts and directory setup only
  # Settings are dynamic at runtime, not managed by Nix
  
  home.packages = with pkgs; [
    swaybg
    fzf
  ];

  # Create wallpaper directory
  home.file.".config/sway/wallpapers/.gitkeep".text = "";

  # Wallpaper switcher script - interactive selection
  home.file.".local/bin/switch-wallpaper.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      source {{.LOGLIB_PATH}}

      WALLPAPER_DIR="''${HOME}/.config/sway/wallpapers"

      if [[ $# -eq 0 ]]; then
        # Interactive selection via fzf
        selected=$(find "''${WALLPAPER_DIR}" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" \) | fzf --preview "echo {}" --preview-window hidden)
      else
        selected="$1"
      fi

      if [[ -f "''${selected}" ]]; then
        ln -sf "''${selected}" "''${HOME}/.config/sway/background.png"
        
        # Reload wallpaper on Sway
        pkill -SIGUSR2 swaybg 2>/dev/null || true
        swaybg -i "''${selected}" &
        
        log_success "Wallpaper changed to: $(basename "''${selected}")"
      else
        log_error "Wallpaper not found: ''${selected}"
        exit 1
      fi
    '';
    executable = true;
  };

  # Wallpaper rotation script - optional auto-rotate daemon
  home.file.".local/bin/rotate-wallpaper.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      source {{.LOGLIB_PATH}}

      WALLPAPER_DIR="''${HOME}/.config/sway/wallpapers"
      INTERVAL=''${1:-300} # Default 5 minutes

      log_info "Starting wallpaper rotation every $INTERVAL seconds"

      while true; do
        wallpaper=$(find "''${WALLPAPER_DIR}" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" \) | shuf -n 1)
        
        if [[ -f "''${wallpaper}" ]]; then
          ln -sf "''${wallpaper}" "''${HOME}/.config/sway/background.png"
          pkill -SIGUSR2 swaybg 2>/dev/null || true
          swaybg -i "''${wallpaper}" &
          log_info "Rotated to: $(basename "''${wallpaper}")"
        fi

        sleep "$INTERVAL"
      done
    '';
    executable = true;
  };
}
