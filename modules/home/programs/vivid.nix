{ config, lib, ... }:
let
  cfg = config.programs.vivid;
  generateArgs =
    lib.optionals (cfg.colorMode != null) [
      "-m"
      cfg.colorMode
    ]
    ++ [ "generate" ]
    ++ lib.optional (cfg.activeTheme != null) cfg.activeTheme;
in
{
  programs.vivid = {
    enable = true;

    enableBashIntegration = false;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.bash.initExtra = lib.mkIf (cfg.package != null) ''
    export LS_COLORS="$(${lib.getExe cfg.package} ${lib.escapeShellArgs generateArgs})"
  '';
}
