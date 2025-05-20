{
  lib,
  pkgs,
  config,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in
{
  home.file.".npmrc" = {
    text = ''
      prefix = ''\${HOME}/.local/share/.npm-packages
    '';
  };

  home.activation.npmPackages = activationUtils.mkPackageManager {
    name = "npm";
    basePackages = [
      "yarn"
    ];
    additionalPackages =
      if userConfig ? npm && userConfig.npm ? additionalPackages then
        userConfig.npm.additionalPackages
      else
        [ ];
    executableArguments = [
      "install"
      "-g"
    ];
    executableName = "npm";
  };

  launchd.agents.copilot-api = {
    enable = true;
    config = {
      Label = "com.user.copilot-api";
      ProgramArguments = [
        "${pkgs.nodejs}/bin/npx"
        "copilot-api@latest"
        "start"
        "--port"
        "4141"
        "--wait"
      ];
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false; # Restart if exits with non-zero status
        Crashed = true; # Restart if crashes
      };
      ThrottleInterval = 30; # Wait 30 seconds between restarts to avoid rapid cycling
      StartInterval = 300; # Check every 5 minutes if service needs to be restarted
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/copilot-api.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/copilot-api-error.log";
      EnvironmentVariables = {
        PATH = "${pkgs.nodejs}/bin:${config.home.homeDirectory}/.npm-packages/bin:/usr/local/bin:/usr/bin:/bin";
      };
    };
  };
}

