{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.eza;
in
{
  config = mkIf cfg.enable {
    programs.eza = {
      enableBashIntegration = true;
      enableZshIntegration = true;

      git = true;
      icons = "auto";
      colors = "auto";

      extraOptions = [
        "--time-style=long-iso"
      ];
    };
  };
}
