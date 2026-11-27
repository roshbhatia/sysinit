{ config, lib, ... }: {
  imports = [ ./options.nix ];

  stylix.targets = {
    rofi.enable = lib.mkDefault config.programs.rofi.enable;
    helix.opacity.enable = false;

    neovim.enable = false;

    vivid.enable = true;

    firefox.enable = false;

    wezterm.enable = false;

    waybar.addCss = false;
  };
}
