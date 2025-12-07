{
  config,
  lib,
  ...
}:
with lib;
{
  config = {
    programs.carapace = {
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
