{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.carapace;
in
{
  config = mkIf cfg.enable {
    programs.carapace = {
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
