{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.darwin = {
    aerospace = {
      outerGaps = {
        top = mkOption {
          type = types.int;
          default = 56;
          description = "Outer top gap in points (should clear sketchybar + notch)";
        };
        bottom = mkOption {
          type = types.int;
          default = 8;
          description = "Outer bottom gap in points";
        };
      };
    };

    lima = {
      instanceName = mkOption {
        type = types.str;
        default = "";
        description = "Name of the Lima NixOS VM instance to auto-start on login (empty = disabled)";
      };
    };

    colima = {
      cpu = mkOption {
        type = types.int;
        default = 2;
        description = "Number of CPUs to allocate to the Colima VM";
      };
      memory = mkOption {
        type = types.int;
        default = 4;
        description = "Memory in GiB to allocate to the Colima VM";
      };
      disk = mkOption {
        type = types.int;
        default = 100;
        description = "Container data disk size in GiB";
      };
      forwardAgent = mkOption {
        type = types.bool;
        default = true;
        description = "Forward the host SSH agent into the Colima VM";
      };
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
