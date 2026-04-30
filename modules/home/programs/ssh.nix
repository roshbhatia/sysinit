{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv) isLinux;
  sshCfg = config.sysinit.git.ssh;

  use1Password = sshCfg.use1PasswordAgent;
  inherit (sshCfg) agentSocket;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        hashKnownHosts = true;
      }
      // lib.optionalAttrs use1Password {
        extraOptions = {
          IdentityAgent = ''"${agentSocket}"'';
        };
      }
      // lib.optionalAttrs (!use1Password) {
        identitiesOnly = true;
      };

      "vorgossos" = {
        hostname = "vorgossos.stork-eel.ts.net";
        user = "rshnbhatia";
      };

      "huey" = {
        hostname = "huey.taila415c.ts.net";
        user = "rosh";
      };
    };
  };

  home.file = lib.optionalAttrs isLinux {
    ".ssh/authorized_keys" = {
      text = ''
        # GitHub SSH Key - from 1Password
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV
      '';
    };
  };
}
