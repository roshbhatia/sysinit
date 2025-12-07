{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.zoxide;
in
{
  config = mkIf cfg.enable {
    programs.zoxide = {
      enableZshIntegration = false; # Handled manually in zsh config
      enableNushellIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
