{ values, ... }:
{
  nix = {
    enable = true;
    settings = {
      trusted-users = [
        "root"
        "@admin"
        values.user.username
      ];
    };

    linux-builder = {
      enable = true;
      ephemeral = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 4;
        };
      };
    };
  };
}
