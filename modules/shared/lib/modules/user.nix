{ lib, ... }:

with lib;

{
  options.sysinit.user = {
    username = mkOption {
      type = types.str;
      default = "user";
      description = "Username for the system user";
    };
  };
}
