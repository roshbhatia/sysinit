{
  # Common configuration for all personal machines
  common = {
    user = {
      username = "rshnbhatia";
    };

    git = {
      name = "Roshan Bhatia";
      email = "rshnbhatia@gmail.com";
      username = "roshbhatia";
    };
  };

  # Host-specific configurations
  hosts = {
    # lv426 - Personal MacBook Pro (aarch64-darwin)
    lv426 = {
      system = "aarch64-darwin";
      hostname = "lv426";

      # Darwin-specific configuration
      darwin = {
        homebrew = {
          additionalPackages = {
            taps = [ "qmk/qmk" ];
            brews = [ "qmk" ];
            casks = [
              "betterdiscord-installer"
              "calibre"
              "discord"
              "orbstack"
              "steam"
            ];
          };
        };
      };
    };

    # arrakis - Gaming Desktop (x86_64-linux)
    arrakis = {
      system = "x86_64-linux";
      hostname = "arrakis";

      # NixOS-specific configuration
      nixos = {
        # Gaming packages are defined in hosts/arrakis/default.nix
      };
    };

    # urth - Home Server (x86_64-linux)
    urth = {
      system = "x86_64-linux";
      hostname = "urth";

      # NixOS-specific configuration
      nixos = {
        # k3s configuration is defined in hosts/urth/default.nix
      };
    };
  };
}
