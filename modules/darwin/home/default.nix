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

  environment.pathsToLink = [ "/share/zsh" ];
  
  home.activation.pruneBrokenLinks = lib.hm.dag.entryAfter ["checkLinkTargets"] ''
    echo "Pruning stale Home-Manager symlinks..."
    
    # Define allowlisted directories (relative to $homeDirectory)
    declare -A allowlist
    allowlist[".config"]=1
    allowlist[".local/share"]=1
    allowlist["$HOME"]=1
    # Add more allowed directories as needed
    
    # Function to check if path is in an allowlisted directory
    is_allowed() {
      local path="$1"
      local rel_path=''${path#"$homeDirectory/"}
      
      for dir in "''${!allowlist[@]}"; do
        if [[ "$rel_path" == "$dir"* || "$rel_path" == "$dir" ]]; then
          return 0  # Path is in allowlist
        fi
      done
      
      return 1  # Path is not in allowlist
    }
    
    find "${homeDirectory}" -type l | while read -r link; do
      # Check if the link is in an allowlisted directory
      if is_allowed "$link"; then
        target=$(readlink "$link")
        if [ ! -e "$target" ]; then
          echo "Removing stale symlink: $link -> $target"
          rm "$link"
        fi
      else
        # Optional: Uncomment to see skipped links
        # echo "Skipping symlink outside allowlist: $link"
        :
      fi
    done
  '';
}