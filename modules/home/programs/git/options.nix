{ lib, ... }:

{
  options.sysinit.git = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git user name";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Git user email";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "Git/GitHub username";
    };

    defaultIdentity = lib.mkOption {
      type = lib.types.enum [
        "personal"
        "work"
      ];
      default = "personal";
      description = "Default SSH identity to use for github.com (personal or work)";
    };

    personalEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Personal email override";
    };

    workEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Work email override";
    };

    personalUsername = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Personal username override";
    };

    workUsername = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Work username override";
    };

    ssh = {
      use1PasswordAgent = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use 1Password SSH agent instead of file-based keys";
      };

      agentSocket = lib.mkOption {
        type = lib.types.str;
        default = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
        description = "Path to 1Password SSH agent socket";
      };

      personalPublicKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPaCcHii525hx5Roh8kYyisdIjXVG3t4tkKwhcwUwXS";
        description = "Public key for personal GitHub identity (1Password will match this to provide the private key)";
      };

      workPublicKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "ssh-ed25519 AAAA... comment";
        description = "Public key for work GitHub identity (1Password will match this to provide the private key)";
      };

      personalKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to SSH key file for personal identity (fallback if not using 1Password)";
      };

      workKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to SSH key file for work identity (fallback if not using 1Password)";
      };
    };

    # Deprecated - use ssh.personalKeyFile instead
    personalSshKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "DEPRECATED: Use ssh.personalKeyFile instead";
    };

    # Deprecated - use ssh.workKeyFile instead
    workSshKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "DEPRECATED: Use ssh.workKeyFile instead";
    };
  };
}
