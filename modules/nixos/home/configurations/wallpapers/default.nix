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

  # Create background directories
  home.file.".config/background/.gitkeep".text = "";

  # Wallpaper switcher script - interactive selection
  # Uses ~/.background-image symlink for WM/DE compatibility (shared with set-background.nu)
  home.file.".local/bin/switch-wallpaper.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      source {{.LOGLIB_PATH}}

      WALLPAPER_SOURCES=(
        "''${HOME}/.local/share/wallpapers"
        "''${HOME}/Pictures"
        "''${HOME}/Desktop"
      )

      if [[ $# -eq 0 ]]; then
        # Find images from multiple sources
        selected=$(find "''${WALLPAPER_SOURCES[@]}" -maxdepth 3 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | fzf --preview "file {}" --preview-window hidden)
      else
        selected="$1"
      fi

      if [[ -f "''${selected}" ]]; then
        mkdir -p "''${HOME}/.config/background"
        cp "''${selected}" "''${HOME}/.config/background/current"
        ln -sf "''${HOME}/.config/background/current" "''${HOME}/.background-image"
        
        # Reload wallpaper on Sway
        pkill -SIGUSR2 swaybg 2>/dev/null || true
        swaybg -i "''${HOME}/.background-image" &
        
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

      WALLPAPER_SOURCES=(
        "''${HOME}/.local/share/wallpapers"
        "''${HOME}/Pictures"
      )

      INTERVAL=''${1:-300} # Default 5 minutes

      log_info "Starting wallpaper rotation every $INTERVAL seconds"

      while true; do
        wallpapers=()
        for source in "''${WALLPAPER_SOURCES[@]}"; do
          [[ -d "''${source}" ]] && mapfile -t -O ''${#wallpapers[@]} wallpapers < <(find "''${source}" -maxdepth 3 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null)
        done

        if [[ ''${#wallpapers[@]} -eq 0 ]]; then
          log_warn "No wallpapers found"
          sleep "$INTERVAL"
          continue
        fi

        wallpaper="''${wallpapers[$((RANDOM % ''${#wallpapers[@]}))]}"
        
        if [[ -f "''${wallpaper}" ]]; then
          mkdir -p "''${HOME}/.config/background"
          cp "''${wallpaper}" "''${HOME}/.config/background/current"
          ln -sf "''${HOME}/.config/background/current" "''${HOME}/.background-image"
          pkill -SIGUSR2 swaybg 2>/dev/null || true
          swaybg -i "''${HOME}/.background-image" &
          log_info "Rotated to: $(basename "''${wallpaper}")"
        fi

        sleep "$INTERVAL"
      done
    '';
    executable = true;
  };
}
