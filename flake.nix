{
  description = "Roshan's OSX DevEnv System Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, ... }@inputs:
  let
    system = "aarch64-darwin"; # For Apple Silicon
    
    # Load and validate configuration
    loadConfig = configPath:
      let
        defaultConfig = import ./config.nix;
        
        # Verify config file exists
        configExists = builtins.pathExists configPath;
        
        # Import user config or use empty set if not found
        userConfig = 
          if configExists then
            import configPath
          else
            throw "ERROR: Configuration file not found at ${toString configPath}";
            
        # Merge configurations
        config = nixpkgs.lib.recursiveUpdate defaultConfig userConfig;
        
        # Validate required fields
        requiredFields = [
          { path = ["user" "username"]; name = "user.username"; }
          { path = ["user" "hostname"]; name = "user.hostname"; }
          { path = ["git" "userName"]; name = "git.userName"; }
          { path = ["git" "userEmail"]; name = "git.userEmail"; }
          { path = ["git" "githubUser"]; name = "git.githubUser"; }
        ];
        
        # Check each required field
        checkField = field:
          let
            value = nixpkgs.lib.attrByPath field.path null config;
          in
          if value == null then
            throw "ERROR: Missing required field ${field.name}"
          else
            true;
            
        # Validate all required fields
        _ = builtins.all (field: checkField field) requiredFields;
        
        # Validate wallpaper if specified
        __ = if (config ? wallpaper && config.wallpaper ? path) then
              let 
                path = config.wallpaper.path;
                resolvedPath = if nixpkgs.lib.strings.hasPrefix "/" path
                              then path
                              else toString (self + "/${path}");
                pathExists = builtins.pathExists resolvedPath;
              in
              if !pathExists then
                builtins.trace "WARNING: Wallpaper file not found at ${resolvedPath}" true
              else true
            else true;
            
        # Validate install files
        ___ = if (config ? install && builtins.isList config.install) then
               let
                 validateFile = file:
                   if !(file ? source && file ? destination) then
                     builtins.trace "WARNING: Invalid file config in install list" false
                   else true;
               in
               builtins.all (file: validateFile file) config.install
             else true;
      in config;
    
    # Generate darwin configuration
    mkDarwinConfig = { configPath ? ./config.nix }: 
    let
      config = loadConfig configPath;
      username = config.user.username;
      hostname = config.user.hostname;
      homeDirectory = "/Users/${username}";
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { 
        inherit inputs username homeDirectory; 
        userConfig = config;
        enableHomebrew = true;
      };
      modules = [
        # Base system configuration
        ./modules/darwin/darwin.nix
        
        # Home Manager configuration
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs username homeDirectory; userConfig = config; };
            backupFileExtension = "backup";
            users.${username} = { pkgs, ... }: {
              imports = [ ./modules/home ];
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.enableNixpkgsReleaseCheck = false;
            };
          };
        }
        
        # Set hostname
        { networking.hostName = hostname; }
        
        # Install files from config
        {
          system.activationScripts.extraUserActivation.text = 
            let
              installFiles = if (config ? install && builtins.isList config.install) 
                            then config.install
                            else [];
              
              # Generate installation commands
              installCommands = builtins.concatStringsSep "\n" (
                builtins.map (file: 
                  let 
                    sourcePath = if nixpkgs.lib.strings.hasPrefix "/" file.source
                                then file.source
                                else "${toString self}/${file.source}";
                  in
                  ''
                    echo "Installing ${file.source} to ${file.destination}"
                    mkdir -p "$(dirname "${file.destination}")"
                    cp "${sourcePath}" "${file.destination}"
                  ''
                ) installFiles
              );
            in
            ''
              # Install custom files
              ${installCommands}
            '';
        }
      ];
    };
  in {
    darwinConfigurations = {
      # Default configuration
      default = mkDarwinConfig {};
      
      # Configuration based on hostname from default config
      "${(import ./config.nix).user.hostname}" = mkDarwinConfig {};
    };
    
    # Helper functions
    lib = {
      mkConfigWithFile = configPath: mkDarwinConfig { inherit configPath; };
      defaultConfigPath = ./config.nix;
    };
    
    # For use in other flakes
    darwinModules = {
      # Core system module
      default = { username, homeDirectory ? "/Users/${username}", config ? {}, ... }: {
        imports = [ ./modules/darwin/darwin.nix ];
        _module.args = {
          inherit username homeDirectory inputs;
          userConfig = config;
          enableHomebrew = true;
        };
      };
      
      # Home manager module
      home = { username, homeDirectory ? "/Users/${username}", config ? {}, ... }: {
        imports = [ ./modules/home ];
        home.username = username;
        home.homeDirectory = homeDirectory;
        _module.args.userConfig = config;
      };
    };
    
    # For simpler commands
    packages.${system}.default = self.darwinConfigurations.default.system;
  };
}