{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.direnv;
in
{
  config = mkIf cfg.enable {
    programs = {
      direnv = {
        enableZshIntegration = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
