{
  description = "Nix-on-Droid configuration for Arda, the BOOX Go Color 7";
  nixConfig = {
    extra-substituters = [ "https://nix-on-droid.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/1c872b8c508bbbfebc1b0b74777ff391ce0a574c";
    home-manager = {
      url = "github:nix-community/home-manager/5b76c5b8eec25fdbce4f43309b3ee10584374a26";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/3264519d7df25f82e716e83607acf5e61f89b1ea";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-on-droid,
      ...
    }:
    let
      hostName = "arda";
    in
    {
      nixOnDroidConfigurations.${hostName} = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          overlays = [ nix-on-droid.overlays.default ];
        };
        extraSpecialArgs = { inherit hostName; };
        home-manager-path = home-manager.outPath;
        modules = [ ./configuration.nix ];
      };
    };
}
