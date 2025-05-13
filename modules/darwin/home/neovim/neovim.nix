{
  config,
  lib,
  pkgs,
  ...
}:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
  nvimConfigDir = "${config.home.homeDirectory}/.config/nvim";
  nvimInitSource = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim/init.lua";
  nvimLuaSource = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim/lua";
  nvimInitTarget = "${nvimConfigDir}/init.lua";
  nvimLuaTarget = "${nvimConfigDir}/lua";
in
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
  };

  home.activation.mkNeovimSymlinks = activationUtils.mkActivationScript {
    description = "Symlink Neovim init.lua and lua directory";
    script = ''
      mkdir -p "${nvimConfigDir}"

      echo "Source: ${nvimInitSource}"
      echo "Target: ${nvimInitTarget}"

      if [ -L "${nvimInitTarget}" ]; then
        current_dest=$(readlink -f "${nvimInitTarget}")
        source_real=$(realpath "${nvimInitSource}")
        
        echo "Current symlink points to: $current_dest"
        echo "Source real path: $source_real"
        
        if [ "$current_dest" != "$source_real" ]; then
          echo "Removing existing symlink and creating new one"
          rm "${nvimInitTarget}"
          ln -sf "$source_real" "${nvimInitTarget}"
        else
          echo "Symlink already points to the correct location"
        fi
      elif [ -e "${nvimInitTarget}" ]; then
        echo "Target exists but is not a symlink, removing and creating symlink"
        rm -f "${nvimInitTarget}"
        ln -sf "${nvimInitSource}" "${nvimInitTarget}"
      else
        echo "Creating new symlink"
        ln -sf "${nvimInitSource}" "${nvimInitTarget}"
      fi

      if [ -L "${nvimLuaTarget}" ]; then
        current_dest=$(readlink -f "${nvimLuaTarget}")
        source_real=$(realpath "${nvimLuaSource}")
        
        if [ "$current_dest" != "$source_real" ]; then
          rm "${nvimLuaTarget}"
          ln -sf "$source_real" "${nvimLuaTarget}"
        fi
      elif [ -e "${nvimLuaTarget}" ]; then
        rm -rf "${nvimLuaTarget}"
        ln -sf "${nvimLuaSource}" "${nvimLuaTarget}"
      else
        ln -sf "${nvimLuaSource}" "${nvimLuaTarget}"
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

  home.activation.neovimPermissions = activationUtils.mkActivationScript {
    description = "Setting VSCode key repeat preferences for Neovim";
    after = [
      "setupActivationUtils"
      "writeBoundary"
    ];
    script = ''
      log_command "/usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false" "Configuring VSCode key repeat"
    '';
  };
}
