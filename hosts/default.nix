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

  rosefine = {
    scheme = "rosefine";
    author = "Roshan Bhatia";
    base00 = "1A0F14";
    base01 = "23202E";
    base02 = "2E2A3C";
    base03 = "9692AB";
    base04 = "A8A5B5";
    base05 = "C0BCD0";
    base06 = "D0CCDF";
    base07 = "E1DDEC";
    base08 = "D19DA9";
    base09 = "C49B7A";
    base0A = "D5C497";
    base0B = "8FB5A8";
    base0C = "97ADC2";
    base0D = "94A8D0";
    base0E = "B0A0CC";
    base0F = "B4939F";
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
    theme.base16Scheme = "gruvbox-dark-hard";
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
        base16Scheme = rosefine;
        font.monospace = "WumpusMono Nerd Font Mono";
      };
    };
  };
}
