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

  personalSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPaCcHii525hx5Roh8kYyisdIjXVG3t4tkKwhcwUwXS rshnbhatia@arrakis"
  ];

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
    theme.base16Scheme = rosePine;
    darwin.openssh = {
      enable = true;
      authorizedKeys = personalSshKeys;
    };
  };

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    profile = "workstation";
    desktop = true;
    hardware = ../modules/nixos/hardware/arrakis.nix;
    inherit (personal) username;
    values = personal.values // {
      git = personal.values.git // {
        ssh = personal.values.git.ssh // {
          use1PasswordAgent = false;
          identityFile = "~/.ssh/id_ed25519_personal";
        };
      };
      theme = {
        base16Scheme = roseprime;
        font.monospace = "WumpusMono Nerd Font Mono";
      };
    };
  };
}
