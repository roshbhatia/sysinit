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
    
    # Load the config file with defaults and comprehensive validation
    loadConfig = configPath:
      let
        defaultConfig = import ./config.nix;
        
        # First verify that the config file exists
        configExists = builtins.pathExists configPath;
        _ = if !configExists then
              throw "ERROR: Configuration file not found at ${toString configPath}"
            else true;
            
        # Try to import the config file with better error handling
        customConfig = 
          if configExists then
            import configPath
          else {};
            
        # Try to catch import errors
        __ = let
               importTest = builtins.tryEval (if configExists then import configPath else {});
             in
               if !importTest.success then
                 throw "ERROR: Failed to import configuration file at ${toString configPath}. Check for syntax errors."
               else true;
             
        # Merge configurations with careful update strategy
        mergedConfig = nixpkgs.lib.recursiveUpdate defaultConfig customConfig;
        
        # Validate essential user configuration with detailed error messages
        ___ = if !(mergedConfig ? user) then
                throw "ERROR: Configuration is missing required 'user' section"
              else if !(mergedConfig.user ? username) then
                throw "ERROR: Configuration is missing required user.username property"
              else if !(mergedConfig.user ? hostname) then
                throw "ERROR: Configuration is missing required user.hostname property"
              else true;
            
        # Validate git configuration with detailed error messages
        ____ = if !(mergedConfig ? git) then
                 throw "ERROR: Configuration is missing required 'git' section"
               else
                 let
                   requiredGitProps = ["userName" "userEmail" "credentialUsername" "githubUser"];
                   missingProps = nixpkgs.lib.filter (prop: !(mergedConfig.git ? ${prop})) requiredGitProps;
                 in
                 if missingProps != [] then
                   throw "ERROR: Git configuration is missing required properties: ${toString missingProps}"
                 else true;
             
        # Log optional git properties that could be set
        _____ = let 
          optionalGitProps = ["personalEmail" "workEmail" "personalGithubUser" "workGithubUser"];
          missingOptionalProps = nixpkgs.lib.filter (prop: !(mergedConfig.git ? ${prop})) optionalGitProps;
        in
        if missingOptionalProps != [] then
          builtins.trace "Note: Optional git properties not set: ${toString missingOptionalProps}" 
          true
        else true;
        
        # Validate wallpaper configuration if it exists
        ______ = if (mergedConfig ? wallpaper && mergedConfig.wallpaper ? path) then
                  let 
                    path = mergedConfig.wallpaper.path;
                    flakeRoot = inputs.self;
                    resolvedPath = if nixpkgs.lib.strings.hasPrefix "/" path
                                  then path
                                  else toString (flakeRoot + "/${path}");
                    pathExists = builtins.pathExists resolvedPath;
                  in
                  if !pathExists then
                    builtins.trace "WARNING: Wallpaper file not found at ${resolvedPath}, this may cause build failures" true
                  else true
                else true;
        
        # Validate installation files if defined
        _______ = if (mergedConfig ? install && builtins.isList mergedConfig.install) then
                   let
                     validateFile = file:
                       if !(file ? source && file ? destination) then
                         builtins.trace "WARNING: Invalid file config in install list, missing source or destination" false
                       else true;
                     
                     validFiles = builtins.all (file: validateFile file) mergedConfig.install;
                   in
                   if !validFiles then
                     builtins.trace "WARNING: Some install files are improperly configured and may fail during activation" true
                   else true
                 else true;
      in mergedConfig;
    
    # Main darwin configuration function
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
        # Pass user config as userConfig to avoid collisions with module config
        userConfig = config;
        # Always enable homebrew
        enableHomebrew = true;
      };
      modules = [
        # Main system configuration
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
              home.username = pkgs.lib.mkForce username;
              home.homeDirectory = pkgs.lib.mkForce homeDirectory;
              home.enableNixpkgsReleaseCheck = false;
              # Don't reset home.file so modules can define files to install
              nixpkgs = {};
            };
          };
        }
        
        # Set the hostname
        {
          networking.hostName = hostname;
        }
      ];
    };
    
    # Helper module for including in other flakes
    darwinModules = {
      # Core system module for use in other flakes
      default = { username, homeDirectory ? "/Users/${username}", config ? {}, ... }: {
        imports = [
          ./modules/darwin/darwin.nix
        ];
        
        # Pass the required parameters
        _module.args = {
          inherit username homeDirectory inputs;
          userConfig = config;
          enableHomebrew = true;
        };
      };
      
      # Home manager module for use in other flakes
      home = { username, homeDirectory ? "/Users/${username}", config ? {}, ... }: {
        imports = [ ./modules/home ];
        home.username = username;
        home.homeDirectory = homeDirectory;
        _module.args.userConfig = config;
      };
    };
    
    # Simple bootstrap configuration for initial nix-darwin installation
    bootstrapConfig = 
    let
      # Load default config for bootstrap
      config = import ./config.nix;
      bootstrapUsername = config.user.username;
      bootstrapHomeDirectory = "/Users/${bootstrapUsername}";
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { 
        username = bootstrapUsername;
        homeDirectory = bootstrapHomeDirectory;
        userConfig = config;
      };
      modules = [{
        # Minimal configuration
        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;
        # Don't change this
        system.stateVersion = 4;
        users.users.${bootstrapUsername}.home = bootstrapHomeDirectory;
        # Determinate systems installer should manage nix install
        nix.enable = false;
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
          git
          curl
        ];
        system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
        system.defaults.finder.AppleShowAllExtensions = true;
        security.pam.services.sudo_local.touchIdAuth = true;
      }];
    };
  in {
    # Main usable configurations
    darwinConfigurations = let
      # Load default config for configurations
      defaultConfig = import ./config.nix;
    in {
      # Default personal configuration with default config file
      default = mkDarwinConfig {};
      
      # Also set as hostname-based configuration for simplified commands
      "${defaultConfig.user.hostname}" = mkDarwinConfig {};
      
      # Bootstrap configuration for initial setup
      bootstrap = bootstrapConfig;
    };
    
    # Helper functions for creating configurations
    lib = {
      # Create a configuration with custom config file
      mkConfigWithFile = configPath: mkDarwinConfig { inherit configPath; };
      
      # The default config file path
      defaultConfigPath = ./config.nix;
    };
    
    # Modules for use in other flakes
    inherit darwinModules;
    
    # For simpler commands
    packages.${system}.default = self.darwinConfigurations.default.system;
  };
}