{ config, lib, ... }:
let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
  weztermLuaSource = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/wezterm/wezterm.lua";
  weztermConfigDir = "${config.home.homeDirectory}/.config/wezterm";
  weztermConfigTarget = "${weztermConfigDir}/wezterm.lua";
in
{
  home.activation.mkWeztermSymlink = activationUtils.mkActivationScript {
    description = "Symlink wezterm.lua to .config/wezterm";
    script = ''
      log_info "Ensuring symlink for wezterm.lua in ${weztermConfigDir}"
      mkdir -p "${weztermConfigDir}"
      
      echo "Source: ${weztermLuaSource}"
      echo "Target: ${weztermConfigTarget}"
      
      if [ -L "${weztermConfigTarget}" ]; then
        current_dest=$(readlink -f "${weztermConfigTarget}")
        source_real=$(realpath "${weztermLuaSource}")
        
        echo "Current symlink points to: $current_dest"
        echo "Source real path: $source_real"
        
        if [ "$current_dest" != "$source_real" ]; then
          echo "Removing existing symlink and creating new one"
          rm "${weztermConfigTarget}"
          ln -sf "$source_real" "${weztermConfigTarget}"
        else
          echo "Symlink already points to the correct location"
        fi
      elif [ -e "${weztermConfigTarget}" ]; then
        echo "Target exists but is not a symlink, removing and creating symlink"
        rm -f "${weztermConfigTarget}"
        ln -sf "${weztermLuaSource}" "${weztermConfigTarget}"
      else
        echo "Creating new symlink"
        ln -sf "${weztermLuaSource}" "${weztermConfigTarget}"
      fi
    '';
    requiredExecutables = [
      "ln"
      "mkdir"
      "readlink"
      "realpath"
      "rm"
    ];
  };
}
