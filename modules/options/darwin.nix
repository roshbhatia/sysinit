{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.darwin = {
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
