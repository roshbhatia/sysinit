{
  description = "Host-specific configuration consuming roshbhatia/sysinit";

  inputs = {
    # Point to sysinit (use local path for development, remote for production)
    # sysinit.url = "path:/path/to/sysinit";
    sysinit.url = "github:roshbhatia/sysinit";

    # Follow all inputs from sysinit for consistency
    darwin.follows = "sysinit/darwin";
    determinate.follows = "sysinit/determinate";
    direnv-instant.follows = "sysinit/direnv-instant";
    firefox-addons.follows = "sysinit/firefox-addons";
    home-manager.follows = "sysinit/home-manager";
    neovim-nightly-overlay.follows = "sysinit/neovim-nightly-overlay";
    nixpkgs.follows = "sysinit/nixpkgs";
    nixos-lima.follows = "sysinit/nixos-lima";
    nur.follows = "sysinit/nur";
    onepassword-shell-plugins.follows = "sysinit/onepassword-shell-plugins";
    stylix.follows = "sysinit/stylix";
  };

  outputs =
    inputs@{
      sysinit,
      darwin,
      home-manager,
      stylix,
      onepassword-shell-plugins,
      ...
    }:
    let
      inherit (sysinit.inputs) nixpkgs;
      inherit (nixpkgs) lib;

      # Re-instantiate sysinit lib with host inputs
      sysinitLib = import (sysinit + /lib) {
        inherit lib nixpkgs inputs;
      };

      builders = sysinitLib.builders;
      outputBuilders = sysinitLib.outputBuilders;

      # Host-specific values
      hostValues = {
        username = "yourusername";

        git = {
          name = "Your Name";
          email = "your.email@example.com";
          username = "yourgithub";
        };

        theme = {
          appearance = "dark";
          colorscheme = "catppuccin";
          variant = "frappe";
          font.monospace = "TX-02";
          transparency = {
            opacity = 0.8;
            blur = 70;
          };
        };

        darwin = {
          tailscale.enable = false;
          homebrew.additionalPackages = {
            taps = [ ];
            brews = [ ];
            casks = [ ];
          };
        };
      };

      # Define host configurations
      hostConfigs = {
        # macOS machine
        yourhostname = {
          system = "aarch64-darwin";
          platform = "darwin";
          username = hostValues.username;
          values = hostValues // {
            hostname = "yourhostname";
            user.username = hostValues.username;
          };
        };

        # Lima VM (NixOS) - optional
        # yourhostname-vm = {
        #   system = "aarch64-linux";
        #   platform = "linux";
        #   isLima = true;
        #   username = hostValues.username;
        #   values = hostValues // {
        #     hostname = "yourhostname-vm";
        #     user.username = hostValues.username;
        #   };
        # };
      };

      # Add host-specific overlays
      mkHostOverlays =
        system: (builders.mkOverlays system) ++ (import ./overlays { inherit inputs system; });

      buildConfig = builders.buildConfiguration {
        inherit
          darwin
          home-manager
          stylix
          onepassword-shell-plugins
          ;
        inherit (builders) mkPkgs mkUtils;
        mkOverlays = mkHostOverlays;
      };

      darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
      nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

    in
    {
      darwinConfigurations = outputBuilders.mkConfigurations {
        configs = darwinConfigs;
        inherit buildConfig;
        extraModules = [ ./modules/darwin ];
      };

      nixosConfigurations = outputBuilders.mkConfigurations {
        configs = nixosConfigs;
        inherit buildConfig;
        extraModules = [ ./modules/nixos ];
      };

      lib = {
        inherit builders hostConfigs hostValues;
      };
    };
}
