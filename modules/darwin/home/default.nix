{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  installFiles = userConfig.install or [];

  # Convert install entries to home.file and xdg.configFile attrs
  fileAttrs = lib.foldl (acc: entry:
    let
      # Use entry.source as path; configValidator ensures it's a path
      srcPath = entry.source;
      relPath = lib.removePrefix "/Users/${username}/" entry.destination;
      isConfig = lib.hasPrefix ".config/" relPath;
      configPath = lib.removePrefix ".config/" relPath;
      homePath = relPath;
      # Determine executability based on file extension or destination path
      srcStr = toString entry.source;
      isExecutable = lib.hasInfix "/bin/" entry.destination
                   || lib.hasSuffix ".sh" srcStr
                   || lib.hasSuffix ".expect" srcStr;
      attrs = {
        source = srcPath;
        executable = isExecutable;
      };
    in
    if isConfig
    then acc // { xdg.configFiles.${configPath} = attrs; }
    else acc // { homeFiles.${homePath} = attrs; }
  ) { xdg.configFiles = {}; homeFiles = {}; } installFiles;
in {
  imports = [
    ./core/packages.nix
    ./wallpaper/wallpaper.nix
    ./git/git.nix
    ./npm/npm.nix
    ./pipx/pipx.nix
    ./go/go.nix
    ./zsh/zsh.nix
    ./atuin/atuin.nix
    ./colima/colima.nix
    ./neovim/neovim.nix
    ./k9s/k9s.nix
    ./aerospace/aerospace.nix
    ./macchina/macchina.nix
    ./wezterm/wezterm.nix
  ];

  
  xdg.configFile = fileAttrs.xdg.configFiles;
  home.file = fileAttrs.homeFiles;

  home.activation.pruneBrokenLinks = lib.hm.dag.entryAfter ["checkLinkTargets"] ''
    echo "Pruning stale home-manager symlinks..."
    
    # Only check specific home-manager managed directories
    for dir in ".config" ".local"; do
      if [ -d "~/$dir" ]; then
        find "~/$dir" -type l | while read -r link; do
          target=$(readlink "$link")
          # Only remove broken links pointing to the nix store
          if [[ "$target" == "/nix/store/"* ]] && [ ! -e "$target" ]; then
            echo "Removing stale home-manager symlink: $link -> $target"
            rm "$link"
          fi
        done
      fi
    done

    # Check direct home directory links but exclude system paths
    find "~" -maxdepth 1 -type l | while read -r link; do
      # Skip if link is in a protected system directory
      if [[ "$link" == *"/Library/Containers/"* ]] || 
         [[ "$link" == *"/Library/Group Containers/"* ]] || 
         [[ "$link" == *"/Library/SystemMigration/"* ]]; then
        continue
      fi
      
      target=$(readlink "$link")
      # Only remove broken links pointing to the nix store
      if [[ "$target" == "/nix/store/"* ]] && [ ! -e "$target" ]; then
        echo "Removing stale home-manager symlink: $link -> $target"
        rm "$link"
      fi
    done
  '';
}