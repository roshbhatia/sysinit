{
  config,
  lib,
  ...
}:
with lib;
{
  config = {
    programs = {
      direnv = {
        enableZshIntegration = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
