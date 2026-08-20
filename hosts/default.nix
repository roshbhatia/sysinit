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

  # Rosé Pine, corrected. base16-schemes ships `rose-pine`, but that port maps
  # base07 to Rosé Pine's `highlightHigh` (#524f67), inverting base16's rule that
  # base07 is the lightest tier. wezterm.nix feeds base07 to ANSI 15, so bright
  # white came out at 2.25:1 against base00 and was unreadable. It also ships
  # three duplicate slots: base06=base05, base0F=base07, base0E=base09, which
  # collapses magenta into orange.
  #
  # Five slots are changed against the upstream port. Every other value is the
  # official palette. Contrast is measured against base00:
  #   base06 #E9E8F7  text lightened 30% toward white   13.39 -> 14.59
  #   base07 #F4F3FB  text lightened 65% toward white    2.25 -> 16.03
  #   base0B #3E8FB0  the Moon variant's brighter pine   3.38 ->  4.84
  #   base0E #D096CE  iris blended 30% with love         dup  ->  7.51
  #   base0F #9C7F87  rose blended 40% with base02       2.25 ->  4.88
  rosePine = {
    scheme = "Rosé Pine";
    author = "Emilia Dunfelt, corrected for base16 slot order";
    base00 = "191724";
    base01 = "1F1D2E";
    base02 = "26233A";
    base03 = "6E6A86";
    base04 = "908CAA";
    base05 = "E0DEF4";
    base06 = "E9E8F7";
    base07 = "F4F3FB";
    base08 = "EB6F92";
    base09 = "F6C177";
    base0A = "EBBCBA";
    base0B = "3E8FB0";
    base0C = "9CCFD8";
    base0D = "C4A7E7";
    base0E = "D096CE";
    base0F = "9C7F87";
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
    theme.base16Scheme = rosePine;
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
        base16Scheme = rosePine;
        font.monospace = "WumpusMono Nerd Font Mono";
      };
    };
  };
}
