{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.darwin = {
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
