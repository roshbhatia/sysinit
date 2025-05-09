{ config, lib, pkgs, ... }:

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
      ln -sf "${nvimInitSource}" "${nvimInitTarget}"
      ln -sf "${nvimLuaSource}" "${nvimLuaTarget}"
    '';
    requiredExecutables = [ "ln" "mkdir" ];
  };

  home.activation.neovimPermissions = activationUtils.mkActivationScript {
    description = "Setting VSCode key repeat preferences for Neovim";
    after = [ "setupActivationUtils" "writeBoundary" ];
    script = ''
      log_command "/usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false" "Configuring VSCode key repeat"
    '';
  };
}
