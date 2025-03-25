{
  description = "Work system configuration using sysinit";

  inputs = {
    sysinit.url = "github:roshbhatia/sysinit";
    nixpkgs.follows = "sysinit/nixpkgs";
    darwin.follows = "sysinit/darwin";
    home-manager.follows = "sysinit/home-manager";
  };

  outputs = { self, nixpkgs, darwin, home-manager, sysinit }: {
    darwinConfigurations.default = sysinit.lib.mkConfigWithFile ./config.nix;
  };
}