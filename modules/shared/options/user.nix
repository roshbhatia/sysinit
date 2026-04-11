{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.sysinit.user = {
    username = mkOption {
      type = types.str;
      default = "user";
      description = "Username for the system user";
    };
  };
}
