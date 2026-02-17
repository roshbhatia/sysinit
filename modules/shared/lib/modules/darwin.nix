{ lib, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.sysinit.darwin = {
    borders = {
      enable = mkEnableOption "JankyBorders window borders";
    };

    tailscale = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Tailscale VPN";
      };
    };

    homebrew = {
      additionalPackages = {
        taps = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Homebrew taps";
        };

        brews = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Homebrew formulas";
        };

        casks = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Homebrew casks";
        };
      };
    };
  };
}
