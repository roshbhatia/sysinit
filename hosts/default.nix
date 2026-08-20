_:
let
  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
    ssh.use1PasswordAgent = true;
  };

  personal = {
    username = "rshnbhatia";
    values = {
      inherit git;
    };
  };

  # neomodern.nvim's `roseprime`, mapped onto the base16 slots. The upstream
  # theme is a Neovim colorscheme: it publishes an ANSI-16 set and a semantic
  # spec, not base00-base0F, so the ramp and four slots are derived here.
  # Derived values, and why each one is not the upstream colour:
  #   base04  fg blended 50% with comment. Upstream's ANSI `white`
  #           (fg darkened 40%) sits at luminance .134 against comment's .122,
  #           which is not a visible step between status text and comments.
  #   base06  fg lightened 30%, base07 fg lightened 62%. base16 wants base05-07
  #           to keep rising and upstream stops at fg; wezterm.nix feeds base07
  #           to ANSI 15, so bright white has to be the lightest tier.
  #   base0A  upstream yellow rotated to hue 48. The palette has one warm hue
  #           (#C9AA95, hue 24), which is the orange base09 wants; base16 needs
  #           a separate yellow. Rotating holds the lightness and the low
  #           saturation, so it stays in the palette's register. dE2000 14.1
  #           from base09.
  #   base0C  upstream green blended 35% into `alt` (cyan lightened 40%).
  #           `alt` alone is dE2000 7.3 from base0D, because the palette's green
  #           and blue are only 53 degrees apart and cyan sits between them.
  #           Pulling it toward green splits the difference: 11.6 from base0D,
  #           10.8 from base0B. That 10.8 is the floor the palette allows.
  #   base0E  upstream magenta blended 40% with red. The magenta is hue 242 to
  #           the blue's 224, dE2000 6.9 apart. Red carries it to hue 267 and
  #           drops saturation from .64 to .30, inside the palette's .20-.34
  #           band, at dE2000 15.1 from base0D.
  # Measured: base00-base07 luminance rises strictly, every accent pair is
  # dE2000 10.8 or more, and every accent is 4.67:1 or better on base00.
  roseprime = {
    scheme = "roseprime";
    author = "casedami (neomodern.nvim), mapped to base16 slots";
    base00 = "141517";
    base01 = "1C1D1F";
    base02 = "27282A";
    base03 = "666068";
    base04 = "958B96";
    base05 = "C4B6C5";
    base06 = "D6CCD6";
    base07 = "E9E3E9";
    base08 = "C4959C";
    base09 = "C9AA95";
    base0A = "C9BF95";
    base0B = "9BBDB8";
    base0C = "9EB8C8";
    base0D = "96AFF2";
    base0E = "B29ECB";
    base0F = "9D777D";
  };

  darwinHost = identity: extraValues: {
    system = "aarch64-darwin";
    platform = "darwin";
    profile = "workstation";
    inherit (identity) username;
    values = identity.values // extraValues;
  };

in
{
  lv426 = darwinHost personal {
    theme.base16Scheme = roseprime;
  };

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    profile = "workstation";
    desktop = true;
    hardware = ../modules/nixos/hardware/arrakis.nix;
    inherit (personal) username;
    values = personal.values // {
      theme = {
        base16Scheme = roseprime;
        font.monospace = "WumpusMono Nerd Font Mono";
      };
    };
  };
}
