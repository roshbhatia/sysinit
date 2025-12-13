{
  config,
  lib,
  pkgs,
  ...
}:

{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.polarity = "dark";
  stylix.image = lib.mkDefault (builtins.fetchurl {
    url = "https://github.com/nix-community/stylix/raw/master/example/wallpaper.jpg";
    sha256 = "1p0j7fg8yg6jzcvw39hxg8dp52l5vxcfbmrq4s07nq8xqw93s8xx";
  });

  stylix.base16Scheme = {
    base00 = "1e1e2e"; # bg
    base01 = "313244"; # bg-alt
    base02 = "45475a"; # fg-alt
    base03 = "585b70"; # comment
    base04 = "6c7086"; # gray
    base05 = "cdd6f4"; # fg
    base06 = "f5e0dc"; # fg-alt
    base07 = "b6e3f0"; # fg
    base08 = "f38ba8"; # red
    base09 = "fab387"; # orange
    base0A = "f9e2af"; # yellow
    base0B = "a6e3a1"; # green
    base0C = "94e2d5"; # cyan
    base0D = "89b4fa"; # blue
    base0E = "cba6f7"; # purple
    base0F = "f2cdcd"; # pink
  };

  stylix.fonts = {
    monospace = {
      name = "Agave Nerd Font";
      package = pkgs.nerd-fonts.agave;
      size = 11;
    };
    sansSerif = {
      name = "DejaVu Sans";
      package = pkgs.dejavu_fonts;
      size = 11;
    };
    serif = {
      name = "DejaVu Serif";
      package = pkgs.dejavu_fonts;
      size = 11;
    };
  };

  stylix.targets = {
    fzf.enable = true;
    helix.enable = true;
    zsh.enable = true;
    waybar.enable = true;
    niri.enable = true;
  };
}
