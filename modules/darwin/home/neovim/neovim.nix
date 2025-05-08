{ config, lib, pkgs, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
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

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "/Users/${config.user.username}/github/personal/roshbhatia/sysinit/modules/darwin/home/neovim";
    force = true;
  };

  # Replace the old activation script with our new framework
  home.activation.neovimPermissions = activationUtils.mkActivationScript {
    description = "Setting VSCode key repeat preferences for Neovim";
    after = [ "setupActivationUtils" "writeBoundary" ];
    script = ''
      log_command "/usr/bin/defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false" "Configuring VSCode key repeat"
    '';
  };
}
