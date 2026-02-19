{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nix-your-shell;
in
{
  options.programs.nix-your-shell = {
    enable = lib.mkEnableOption "nix-your-shell, a wrapper for nix develop or nix-shell to retain the same shell inside the new environment";

    package = lib.mkPackageOption pkgs "nix-your-shell" { };

    enableZshIntegration = lib.mkEnableOption "zsh integration" // {
      default = true;
    };

    enableNushellIntegration = lib.mkEnableOption "nushell integration" // {
      default = true;
    };

    nix-output-monitor = {
      enable = lib.mkEnableOption "nix-output-monitor integration";

      package = lib.mkPackageOption pkgs "nix-output-monitor" { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.package ]
      ++ lib.optional cfg.nix-output-monitor.enable cfg.nix-output-monitor.package;

    programs =
      let
        nom = if cfg.nix-output-monitor.enable then "--nom" else "";
      in
      {
        nushell = lib.mkIf cfg.enableNushellIntegration {
          extraConfig = ''
            source ${
              pkgs.runCommand "nix-your-shell-nushell-config.nu" { } ''
                ${lib.getExe cfg.package} ${nom} nu >> "$out"
              ''
            }
          '';
        };

        zsh.initExtra = lib.mkIf cfg.enableZshIntegration ''
          ${lib.getExe cfg.package} ${nom} zsh | source /dev/stdin
        '';
      };
  };
}

          '';
        };

        zsh.initExtra = lib.mkIf cfg.enableZshIntegration ''
          ${lib.getExe cfg.package} ${nom} zsh | source /dev/stdin
        '';
      };
  };
}
