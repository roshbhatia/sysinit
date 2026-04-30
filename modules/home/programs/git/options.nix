{ lib, pkgs, ... }:

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

    ssh = {
      use1PasswordAgent = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use 1Password SSH agent for non-GitHub hosts";
      };

      agentSocket = lib.mkOption {
        type = lib.types.str;
        default =
          if pkgs.stdenv.isDarwin then
            "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          else
            "~/.1password/agent.sock";
        description = "Path to 1Password SSH agent socket";
      };
    };
  };
}
