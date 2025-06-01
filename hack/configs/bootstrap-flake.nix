{
  description = "Bootstrap configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
    }:
    {
      darwinConfigurations.bootstrap = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          {
            system.stateVersion = 4;
            nix.enable = false;
            programs.zsh.enable = true;
            system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
            system.defaults.finder.AppleShowAllExtensions = true;
          }
        ];
      };
    };
}
