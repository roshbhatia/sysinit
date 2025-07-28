{
  description = "Roshan's macOS DevEnv System Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      system = "aarch64-darwin";
      defaultValues = import ./values.nix;

      mkDarwinConfiguration =
        customValues:
        let
          values = customValues;
          username = values.user.username;
          hostname = values.user.hostname;
        in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              system
              values
              username
              hostname
              ;
          };
          modules = [
            ./modules/nix
            ./modules/darwin
            ./modules/home
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };
    in
     {
       darwinConfigurations = {
         ${defaultValues.user.hostname} = mkDarwinConfiguration defaultValues;
       };

       homeConfigurations = {
         ${defaultValues.user.username} = home-manager.lib.homeManagerConfiguration {
           pkgs = inputs.nixpkgs.legacyPackages.${system};
           modules = [
             {
               home.username = defaultValues.user.username;
               home.homeDirectory = "/Users/${defaultValues.user.username}";
               home.stateVersion = "23.11";
             }
             (import ./modules/home {
               username = defaultValues.user.username;
               values = defaultValues;
             })
           ];
         };
       };

       lib = {
         inherit mkDarwinConfiguration;
         defaultValues = defaultValues;
       };
     };}
