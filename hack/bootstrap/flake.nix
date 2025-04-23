{
  description = "Bootstrap configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs }: {
    darwinConfigurations.bootstrap = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        {
          system.stateVersion = 4;

          # Disable nix-darwin's Nix management as we're using Determinate Systems
          nix.enable = false;

          # Create /etc/zshrc that loads the nix-darwin environment
          programs.zsh.enable = true;

          # Basic macOS defaults
          system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
          system.defaults.finder.AppleShowAllExtensions = true;
        }
      ];
    };
  };
}