{
  description = "Bootstrap configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      darwin,
    }:
    {
      darwinConfigurations.bootstrap = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          {
            programs.zsh.enable = true;
            system.defaults.finder.AppleShowAllExtensions = true;
            system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
            system.stateVersion = 4;
          }
        ];
      };
    };
}
