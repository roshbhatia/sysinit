{
  config,
  lib,
  ...
}:

let
  sshCfg = config.sysinit.git.ssh;

  use1Password = sshCfg.use1PasswordAgent;
  inherit (sshCfg) agentSocket;
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
      };
    }
    // (
      let
        # `settings` is a home-manager DAG, and an entry with no stated position
        # sorts by attribute name. That puts `*.stork-eel.ts.net` ahead of every
        # host it covers, because `*` is 42 in ASCII and a letter is 97. ssh
        # keeps the first value it obtains for a keyword, so the wildcard's User
        # wins over a host block that needs a different one. The hosts below all
        # happened to share the wildcard's user, which hid this. entryBefore
        # pins each host ahead of the wildcard that would otherwise answer for it.
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
