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
    // {
      "vorgossos" = {
        HostName = "vorgossos.stork-eel.ts.net";
        User = "rshnbhatia";
      };

      "arrakis" = {
        HostName = "arrakis.stork-eel.ts.net";
        User = "rshnbhatia";
      };

      "huey" = {
        HostName = "huey.taila415c.ts.net";
        User = "rosh";
      };

      # The tailnet FQDNs match no alias above, and completion offers them from
      # known_hosts, so without these the local username is used and auth fails.
      "*.stork-eel.ts.net" = {
        User = "rshnbhatia";
      };

      "*.taila415c.ts.net" = {
        User = "rosh";
      };
    };
  };
}
