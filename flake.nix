outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, ... }@inputs:
  let
    system = "aarch64-darwin";
    defaultConfigPath = ./config.nix;
    
    # Load the configuration file explicitly
    defaultConfig = import defaultConfigPath;
    
    mkDarwinConfig = configPath:
      let
        # Import the config file
        config = import configPath;
        username = config.user.username;
        hostname = config.user.hostname;
        homeDirectory = "/Users/${username}";
      in darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { 
          inherit inputs username homeDirectory;
          userConfig = config;
          enableHomebrew = if config.homebrew ? enable then config.homebrew.enable else true;
        };
        modules = [
          ./modules/darwin/system.nix
          ./modules/darwin/homebrew.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            networking.hostName = hostname;
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { 
                inherit inputs username homeDirectory; 
                userConfig = config;
              };
              users.${username} = { pkgs, ... }: {
                imports = [ ./modules/darwin/home ];
                home = {
                  inherit username homeDirectory;
                  stateVersion = "23.11";
                };
              };
              backupFileExtension = "backup";
            };
          }
        ];
      };
      
    defaultHostname = defaultConfig.user.hostname;
  in {
    darwinConfigurations.${defaultHostname} = mkDarwinConfig defaultConfigPath;

    lib = {
      mkConfigWithFile = mkDarwinConfig;
      inherit defaultConfigPath;
    };

    packages.${system}.default = self.darwinConfigurations.${defaultHostname}.system;
  };
