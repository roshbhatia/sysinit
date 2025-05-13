{ config, lib, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
  weztermLuaSource = "/Users/${config.user.username}/github/personal/roshbhatia/sysinit/modules/darwin/home/wezterm/wezterm.lua";
  weztermConfigDir = "/Users/${config.user.username}/.config/wezterm";
  weztermConfigTarget = "${weztermConfigDir}/wezterm.lua";
in
{
  home.activation.mkWeztermSymlink = activationUtils.mkActivationScript {
    description = "Symlink wezterm.lua to .config/wezterm";
    script = ''
      log_info "Ensuring symlink for wezterm.lua in ${weztermConfigDir}"
      mkdir -p "${weztermConfigDir}"
      if [ -L "${weztermConfigTarget}" ]; then
        if [ "$(readlink "${weztermConfigTarget}")" = "${weztermLuaSource}" ]; then
          exit 0
        else
          sudo rm "${weztermConfigTarget}"
          ln -sf "${weztermLuaSource}" "${weztermConfigTarget}"
        fi
      elif [ -e "${weztermConfigTarget}" ]; then
        sudo rm -rf "${weztermConfigTarget}"
        ln -sf "${weztermLuaSource}" "${weztermConfigTarget}"
      else
        ln -sf "${weztermLuaSource}" "${weztermConfigTarget}"
      fi
    '';
    requiredExecutables = [
      "ln"
      "mkdir"
      "readlink"
      "rm"
    ];
  };
}
