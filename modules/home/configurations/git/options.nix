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
  };
}
