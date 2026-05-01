{
  config,
  lib,
  values,
  ...
}:

let
  sshCfg = config.sysinit.git.ssh;

  use1Password = sshCfg.use1PasswordAgent;
  inherit (sshCfg) agentSocket;

  isPersonal = values.personal or false;
  limaInstance = values.environment.LIMA_INSTANCE or "";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include lima-generated SSH config when a Lima instance is configured
    includes = lib.optional (limaInstance != "") "~/.lima/${limaInstance}/ssh.config";

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
    } // lib.optionalAttrs isPersonal {
      "vorgossos" = {
        hostname = "vorgossos.stork-eel.ts.net";
        user = "rshnbhatia";
      };

      "arrakis" = {
        hostname = "arrakis.stork-eel.ts.net";
        user = "rshnbhatia";
      };

      "huey" = {
        hostname = "huey.taila415c.ts.net";
        user = "rosh";
      };
    };
  };
}
