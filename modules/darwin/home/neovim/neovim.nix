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
      if [ -L "${nvimInitTarget}" ]; then
        if [ "$(readlink "${nvimInitTarget}")" != "${nvimInitSource}" ]; then
          sudo rm "${nvimInitTarget}"
          ln -sf "${nvimInitSource}" "${nvimInitTarget}"
        fi
      elif [ -e "${nvimInitTarget}" ]; then
        sudo rm -rf "${nvimInitTarget}"
        ln -sf "${nvimInitSource}" "${nvimInitTarget}"
      else
        ln -sf "${nvimInitSource}" "${nvimInitTarget}"
      fi
      if [ -L "${nvimLuaTarget}" ]; then
        if [ "$(readlink "${nvimLuaTarget}")" != "${nvimLuaSource}" ]; then
          sudo rm "${nvimLuaTarget}"
          ln -sf "${nvimLuaSource}" "${nvimLuaTarget}"
        fi
      elif [ -e "${nvimLuaTarget}" ]; then
        sudo rm -rf "${nvimLuaTarget}"
        ln -sf "${nvimLuaSource}" "${nvimLuaTarget}"
      else
        ln -sf "${nvimLuaSource}" "${nvimLuaTarget}"
      fi
    '';
    requiredExecutables = [
      "ln"
      "mkdir"
      "readlink"
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
