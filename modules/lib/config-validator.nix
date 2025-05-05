{ nixpkgs, self, ... }:
configPath:

let
  inherit (nixpkgs) lib;
  config = import configPath;

  checkUser = config:
    if !(config ? user) then throw "Missing user configuration"
    else if !(config.user ? username) then throw "Missing username in user configuration"
    else if !(config.user ? hostname) then throw "Missing hostname in user configuration"
    else config;

  checkGit = config:
    if !(config ? git) then throw "Missing git configuration"
    else if !(config.git ? userName) then throw "Missing userName in git configuration"
    else if !(config.git ? userEmail) then throw "Missing userEmail in git configuration"
    else if !(config.git ? githubUser) then throw "Missing githubUser in git configuration"
    else config;

  checkOptionalFields = config:
    let
      checkWallpaper = config:
        if config ? wallpaper && !(config.wallpaper ? path)
        then throw "Wallpaper configuration must include a path"
        else config;

      checkInstall = config:
        if config ? install then
          let
            validateXdgConfigHome = entry:
              if !(entry ? name) then throw "Install entry for XDG config home missing name"
              else if !(entry ? source) then throw "Install entry for XDG config home missing source path"
              else entry;

            validateHome = entry:
              if !(entry ? name) then throw "Install entry for home missing name"
              else if !(entry ? source) then throw "Install entry for home missing source path"
              else entry;
          in
          config // {
            install = {
              installToXdgConfigHome = map validateXdgConfigHome (config.install.installToXdgConfigHome or []);
              installToHome = map validateHome (config.install.installToHome or []);
            };
          }
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
checkOptionalFields (
  checkGit (
    checkUser config
  )
)
