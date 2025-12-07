{
  config,
  lib,
  ...
}:
with lib;
{
  config = {
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
