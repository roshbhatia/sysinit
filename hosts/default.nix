_:
let
  common = {
    username = "rshnbhatia";
    git = {
      name = "Roshan Bhatia";
      email = "rshnbhatia@gmail.com";
      username = "roshbhatia";
      ssh = {
        use1PasswordAgent = true;
      };
    };
  };
in
{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      inherit (common) git;
      environment = {
        LIMA_INSTANCE = "nostromo";
      };
    };
  };

  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    lima = true;
    inherit (common) username;

    values = {
      inherit (common) git;
    };
  };

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    desktop = true;
    hardware = ../modules/nixos/hardware/arrakis.nix;
    inherit (common) username;

    values = {
      inherit (common) git;
      theme = {
        base16Scheme = "everforest-dark-soft";
        appearance = "dark";
        font = {
          monospace = "WumpusMono Nerd Font Mono";
        };
      };
    };
  };

  hyperion = {
    system = "aarch64-darwin";
    platform = "darwin";
    username = "roshan";

    values = {
      inherit (common) git;
      darwin = {
        aerospace.outerGaps = {
          top = 60;
          bottom = 14;
        };
      };
      theme = {
        font = {
          monospace = "WumpusMono Nerd Font Mono";
          icons = "WumpusMono Nerd Font Mono";
          size = 10.0;
          iconYOffset = 0;
          labelYOffset = -1;
        };
      };
    };
  };
}
