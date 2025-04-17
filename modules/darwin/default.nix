{ pkgs, lib, inputs, username, homeDirectory, config, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { 
      inherit inputs username homeDirectory; 
      userConfig = config; 
    };
    users.${username} = { pkgs, ... }: {
      imports = [ ./home ];
      home = {
        inherit username homeDirectory;
        stateVersion = "23.11"; # Keeps home-manager configuration stable
      };
    };
  };
}