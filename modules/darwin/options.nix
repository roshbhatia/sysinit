{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.darwin = {
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

    openssh = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run Apple's built-in sshd, reachable over the tailnet.
          Off by default: a host opts in, because turning it on opens a listener.
        '';
      };

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Public keys that may log in as `sysinit.user.username`. These land in
          /etc/ssh/nix_authorized_keys.d/, not ~/.ssh/authorized_keys.
        '';
      };
    };

    keybindings = {
      symbolicHotkeys = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Whether macOS listens for this shortcut";
              };

              keys = mkOption {
                type = types.nullOr (types.listOf types.int);
                default = null;
                description = "Raw [ character keycode modifiers ] triple, or null to leave the binding untouched";
              };
            };
          }
        );
        default = { };
        description = ''
          macOS system keyboard shortcuts, keyed by Apple's opaque
          AppleSymbolicHotKeys ID. A downstream flake adds a new ID freely, but
          needs `lib.mkForce` to change an ID that keybindings.nix already sets.
        '';
      };

      appShortcuts = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = {
          "com.tinyspeck.slackmacgap" = {
            "Search" = "@$f";
          };
        };
        description = "Per-app menu shortcuts, keyed by preference domain then menu item title";
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
