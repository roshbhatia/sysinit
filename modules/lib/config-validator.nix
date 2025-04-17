# Configuration validator module for sysinit
{ nixpkgs, self, ... }:
configPath:

let
  inherit (nixpkgs) lib;
  config = import configPath;
  
  # Required user fields
  checkUser = config:
    if !(config ? user) then throw "Missing user configuration"
    else if !(config.user ? username) then throw "Missing username in user configuration"
    else if !(config.user ? hostname) then throw "Missing hostname in user configuration"
    else config;

  # Required git fields  
  checkGit = config:
    if !(config ? git) then throw "Missing git configuration"
    else if !(config.git ? userName) then throw "Missing userName in git configuration"
    else if !(config.git ? userEmail) then throw "Missing userEmail in git configuration"
    else if !(config.git ? githubUser) then throw "Missing githubUser in git configuration"
    else config;

  # Optional fields with validation
  checkOptionalFields = config:
    let
      checkWallpaper = config:
        if config ? wallpaper && !(config.wallpaper ? path) 
        then throw "Wallpaper configuration must include a path"
        else config;

      checkInstall = config:
        if config ? install then
          let
            validateEntry = entry:
              if !(entry ? source) then throw "Install entry missing source path"
              else if !(entry ? destination) then throw "Install entry missing destination path"
              else if builtins.typeOf entry.source != "path" then throw "Install entry source must be a path (e.g., ./path/to/file)"
              else if !(lib.strings.hasPrefix "/" entry.destination || lib.strings.hasPrefix "." entry.destination) 
                   then throw "Install entry destination must be an absolute path or start with ./ or .config/"
              else entry;
          in
          config // { install = map validateEntry config.install; }
        else config;
        
      checkHomebrew = config:
        if config ? homebrew && !(config.homebrew ? additionalPackages) 
        then throw "Homebrew configuration must include additionalPackages"
        else config;
        
      checkPipx = config:
        if config ? pipx && !(config.pipx ? additionalPackages) 
        then throw "Pipx configuration must include additionalPackages"
        else config;
        
      checkNpm = config:
        if config ? npm && !(config.npm ? additionalPackages) 
        then throw "Npm configuration must include additionalPackages"
        else config;
    in
    checkNpm (
      checkPipx (
        checkHomebrew (
          checkInstall (
            checkWallpaper config
          )
        )
      )
    );

in
# Apply all validators in sequence, required first then optional
checkOptionalFields (
  checkGit (
    checkUser config
  )
)
