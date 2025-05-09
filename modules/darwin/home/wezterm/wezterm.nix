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
      log_info "Creating symlink for wezterm.lua in ${weztermConfigDir}"
      mkdir -p "${weztermConfigDir}"
      ln -sf "${weztermLuaSource}" "${weztermConfigTarget}"
    '';
    requiredExecutables = [ "ln" "mkdir" ];
  };
}
