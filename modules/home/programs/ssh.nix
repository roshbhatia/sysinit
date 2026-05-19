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

  limaInstance = values.environment.LIMA_INSTANCE or "";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include lima-generated SSH config when a Lima instance is configured
    includes = lib.optional (limaInstance != "") "~/.lima/${limaInstance}/ssh.config";

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
    } // lib.optionalAttrs (limaInstance != "") {
      # wezterm.enumerate_ssh_hosts() doesn't follow Include directives, so we
      # add an explicit block that WezTerm can discover. ProxyCommand delegates
      # to the Lima-generated config which holds the current dynamic port.
      ${limaInstance} = {
        User = values.user.username;
        ProxyCommand = "ssh -F %d/.lima/${limaInstance}/ssh.config lima-${limaInstance} -W 127.0.0.1:22";
        StrictHostKeyChecking = "no";
        UserKnownHostsFile = "/dev/null";
        NoHostAuthenticationForLocalhost = "yes";
      };
    } // {
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
    };
  };
}
