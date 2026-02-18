# Discrete host flake template
# Consumes roshbhatia/sysinit and extends it with host-specific configuration
# Use this template when you need a separate flake for a specific machine/context
{
  description = "Discrete host configuration consuming roshbhatia/sysinit";

  inputs = {
    # Point to sysinit (use local path for development, remote for production)
    # sysinit.url = "git+file:///path/to/personal/sysinit";
    sysinit.url = "github:roshbhatia/sysinit";

    # Follow all inputs from sysinit for consistency
    darwin.follows = "sysinit/darwin";
    determinate.follows = "sysinit/determinate";
    direnv-instant.follows = "sysinit/direnv-instant";
    firefox-addons.follows = "sysinit/firefox-addons";
    home-manager.follows = "sysinit/home-manager";
    neovim-nightly-overlay.follows = "sysinit/neovim-nightly-overlay";
    nix-gaming.follows = "sysinit/nix-gaming";
    nix-homebrew.follows = "sysinit/nix-homebrew";
    nixpkgs.follows = "sysinit/nixpkgs";
    nixos-lima.follows = "sysinit/nixos-lima";
    nur.follows = "sysinit/nur";
    onepassword-shell-plugins.follows = "sysinit/onepassword-shell-plugins";
    stylix.follows = "sysinit/stylix";

    # Host-specific inputs
    # example-tool = {
    #   url = "github:example/tool";
    #   inputs.nixpkgs.follows = "sysinit/nixpkgs";
    # };
  };

  outputs =
    inputs@{
      sysinit,
      darwin,
      home-manager,
      stylix,
      nix-homebrew,
      onepassword-shell-plugins,
      ...
    }:
    let
      inherit (sysinit.inputs) nixpkgs;
      inherit (nixpkgs) lib;

      # Re-instantiate sysinit lib with local inputs
      sysinitLib = import (sysinit + /lib) {
        inherit lib nixpkgs inputs;
      };

      builders = sysinitLib.builders;
      outputBuilders = sysinitLib.outputBuilders;

      # Host-specific values (complete configuration)
      hostValues = {
        username = "your-username";

        git = {
          name = "Your Name";
          email = "your.email@example.com";
          username = "github-username";
          personalEmail = "personal@email.com";
          personalUsername = "personal-github-username";
          workEmail = "work@email.com";
          workUsername = "work-github-username";
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

      # Define hosts locally (don't import from sysinit/hosts)
      hostConfigs = {
        # macOS host
        myhost = {
          system = "aarch64-darwin";
          platform = "darwin";
          username = hostValues.username;
          # Optional: config = ./hosts/myhost.nix;
          values = hostValues // {
            user.username = hostValues.username;
          };
        };

        # NixOS host (e.g., Lima VM)
        # ascalon = {
        #   system = "aarch64-linux";
        #   platform = "linux";
        #   username = hostValues.username;
        #   config = ./hosts/ascalon.nix;
        #   values = hostValues // {
        #     user.username = hostValues.username;
        #   };
        # };
      };

      # Add local overlays on top of sysinit overlays
      mkLocalOverlays =
        system: (builders.mkOverlays system) ++ (import ./overlays { inherit inputs system; });

      buildConfig = builders.buildConfiguration {
        inherit
          darwin
          home-manager
          stylix
          nix-homebrew
          onepassword-shell-plugins
          ;
        inherit (builders) mkPkgs mkUtils;
        mkOverlays = mkLocalOverlays;
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
