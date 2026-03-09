{
  config,
  lib,
  osConfig ? { },
  ...
}:

let
  hasNixOSSystem = osConfig ? system && osConfig.system ? stateVersion;
  isLinux = hasNixOSSystem;
  gitCfg = config.sysinit.git;
  defaultSshKeyFile =
    gitCfg.personalSshKeyFile or gitCfg.workSshKeyFile or throw
      "No default SSH key file configured in git config (personalSshKeyFile or workSshKeyFile)";
in
{
  programs.ssh = {
    enable = true;
    # Disable future-deprecated default config; we set our own matchBlocks."*"
    enableDefaultConfig = false;
    matchBlocks = lib.mkMerge [
      {
        "*" = {
          addKeysToAgent = "yes";
          hashKnownHosts = true;
          identitiesOnly = true;
          identityFile = defaultSshKeyFile;
        };
      }
      (lib.mkIf (defaultSshKeyFile != null) {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = defaultSshKeyFile;
          identitiesOnly = true;
        };
      })
    ];
  };

  home.file = lib.optionalAttrs isLinux {
    ".ssh/authorized_keys" = {
      text = ''
        # GitHub (Default) SSH Key - from 1Password
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV
      '';
    };
  };
}
