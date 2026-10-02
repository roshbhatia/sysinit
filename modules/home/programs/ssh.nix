{
  config,
  lib,
  ...
}:

let
  sshCfg = config.sysinit.git.ssh;

  use1Password = sshCfg.use1PasswordAgent;
  inherit (sshCfg) agentSocket identityFile;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        HashKnownHosts = true;
      }
      // lib.optionalAttrs use1Password {
        IdentityAgent = ''"${agentSocket}"'';
      }
      // lib.optionalAttrs (!use1Password) {
        IdentitiesOnly = true;
      }
      // lib.optionalAttrs (identityFile != null) {
        IdentityFile = identityFile;
      };
    }
    // (
      let

        beforeStork = lib.hm.dag.entryBefore [ "*.stork-eel.ts.net" ];
        beforeTaila = lib.hm.dag.entryBefore [ "*.taila415c.ts.net" ];
      in
      {
        "vorgossos" = beforeStork {
          HostName = "vorgossos.stork-eel.ts.net";
          User = "rshnbhatia";
        };

        "arrakis" = beforeStork {
          HostName = "arrakis.stork-eel.ts.net";
          User = "rshnbhatia";
        };

        "lv426" = beforeStork {
          HostName = "lv426.stork-eel.ts.net";
          User = "rshnbhatia";
        };

        "urth" = beforeStork {
          HostName = "urth.stork-eel.ts.net";
          User = "roshan";
        };

        "huey" = beforeTaila {
          HostName = "huey.taila415c.ts.net";
          User = "rosh";
        };

        "*.stork-eel.ts.net" = {
          User = "rshnbhatia";
        };

        "*.taila415c.ts.net" = {
          User = "rosh";
        };
      }
    );
  };
}
