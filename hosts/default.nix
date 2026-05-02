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
      personal = true;
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
      personal = true;
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
      personal = true;
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
        lima.instanceName = "farcaster";
        colima = {
          cpu = 4;
          memory = 8;
        };
      };
      environment = {
        LIMA_INSTANCE = "farcaster";
      };
      theme = {
        font = {
          monospace = "TX-02";
          size = 10.0;
        };
      };
    };
  };

  farcaster = {
    system = "aarch64-linux";
    platform = "linux";
    lima = true;
    username = "roshan";

    values = {
      inherit (common) git;
      personal = true;
    };
  };
}
