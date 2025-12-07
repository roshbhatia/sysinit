{
  config,
  lib,
  ...
}:
with lib;
{
  config = {
    programs.zoxide = {
      enableZshIntegration = false; # Handled manually in zsh config
      enableNushellIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
