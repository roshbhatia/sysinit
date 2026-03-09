{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  gitCfg = config.sysinit.git;
  sshCfg = gitCfg.ssh;

  use1Password = sshCfg.use1PasswordAgent && isDarwin;

  hasPersonalKey =
    sshCfg.personalPublicKey != null
    || sshCfg.personalKeyFile != null
    || gitCfg.personalSshKeyFile != null;
  hasWorkKey =
    sshCfg.workPublicKey != null || sshCfg.workKeyFile != null || gitCfg.workSshKeyFile != null;

  personalKeyPath =
    if sshCfg.personalKeyFile != null then
      sshCfg.personalKeyFile
    else if use1Password && sshCfg.personalPublicKey != null then
      "~/.ssh/1p_personal.pub"
    else
      gitCfg.personalSshKeyFile;

  workKeyPath =
    if sshCfg.workKeyFile != null then
      sshCfg.workKeyFile
    else if use1Password && sshCfg.workPublicKey != null then
      "~/.ssh/1p_work.pub"
    else
      gitCfg.workSshKeyFile;

  defaultKeyPath = if gitCfg.defaultIdentity == "work" then workKeyPath else personalKeyPath;
  defaultKeyAvailable = if gitCfg.defaultIdentity == "work" then hasWorkKey else hasPersonalKey;

  agentSocket = sshCfg.agentSocket;

  mkGitHubHost =
    keyPath:
    {
      hostname = "github.com";
      user = "git";
    }
    // lib.optionalAttrs use1Password {
      extraOptions = {
        IdentityAgent = ''"${agentSocket}"'';
      };
    }
    // lib.optionalAttrs (keyPath != null) {
      identityFile = keyPath;
      identitiesOnly = true;
    };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = lib.mkMerge [
      {
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
      }

      (lib.mkIf defaultKeyAvailable {
        "github.com" = mkGitHubHost defaultKeyPath;
      })

      (lib.mkIf hasPersonalKey {
        "github-personal" = mkGitHubHost personalKeyPath;
      })

      (lib.mkIf hasWorkKey {
        "github-work" = mkGitHubHost workKeyPath;
      })
    ];
  };

  home.file = lib.mkMerge [
    (lib.optionalAttrs (use1Password && sshCfg.personalPublicKey != null) {
      ".ssh/1p_personal.pub".text = sshCfg.personalPublicKey;
    })

    (lib.optionalAttrs (use1Password && sshCfg.workPublicKey != null) {
      ".ssh/1p_work.pub".text = sshCfg.workPublicKey;
    })

    (lib.optionalAttrs isLinux {
      ".ssh/authorized_keys" = {
        text = ''
          # GitHub (Default) SSH Key - from 1Password
          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbqXvBhZI87E+Jj1i9L1MqQ71JRPofArCC0iRvZRIMV
        '';
      };
    })
  ];
}
