{ lib, inputs }:
# A home-manager configuration with no host underneath it.
#
# `buildConfiguration` reaches home-manager through nix-darwin or NixOS, which
# means the home tree only exists on a machine this repository owns end to end.
# `mkHome` is the other door: `home-manager switch --flake .#dev-x86_64-linux` on
# a box someone else administers.
#
# The home tree reads two specialArgs by name, `values` and `inputs`, plus the
# two this change added, `profile` and `theme`. It used to read a third,
# `utils`, which no `.nix` file dereferences; a search for `utils.` over
# `modules`, `lib`, `hosts`, and `flake.nix` returns nothing, so it is not
# supplied here and phase 4 removed it from the host builders.
#
# `values` is the hard one, because it is read by path rather than as a whole.
# Fourteen paths, derived from the tree rather than written by hand:
#
#   values.darwin              values.theme.appearance
#   values.environment         values.theme.base16Scheme
#   values.git                 values.theme.font
#   values.hostname            values.theme.font.monospace
#   values.isDesktop           values.theme.transparency
#   values.llm                 values.user
#   values.theme               values.user.username
#
# Scoping that search to `.nix` matters. Unscoped it returns sixteen, because
# `neovim/config/after/lsp/helm_ls.lua` holds `values.yaml` and
# `values.lint.yaml`, which are Helm filenames in a lua string.
#
# Five of the fourteen are not leaves: `values.git`, `values.llm`,
# `values.theme`, `values.darwin`, and `values.environment` are open attrsets
# that the consumer either indexes further or forwards whole. They default to
# `{}` here rather than to a shape, because pinning a shape their consumers do
# not agree to is how a standalone build starts lying about the machine.
#
# WHAT IS AN ARGUMENT AND WHAT IS A DEFAULT
#
# `username`, `hostname`, and `system` are arguments with no default, because
# they have no standalone answer. The host builder takes `hostname` from the
# attribute name in `hosts/default.nix` and `username` and `desktop` from fields
# beside `values`; `mkHome` has neither a `hostConfig` nor an attribute name to
# inherit from.
#
# Everything else defaults, and every default is a claim this configuration is
# entitled to make about a machine it has never seen:
#
#   isDesktop  false   a home configuration cannot see whether there is a screen
#   git        {}      the owner's identity is not this builder's to invent
#   llm        {}      same
#   theme      {}      same
#   darwin     {}      same
#   environment {}     same
#   profile    "dev"   toolchains without the workstation layer, which is the
#                      case this door exists for
#   theme      false   there is no stylix module here, so the base16 fallback in
#                      `modules/shared/theme-colors.nix` applies
{
  mkHome =
    {
      home-manager,
      mkPkgs,
      mkOverlays,
    }:
    {
      system,
      username,
      hostname,
      profile ? "dev",
      theme ? false,
      values ? { },
    }:
    let
      pkgs = mkPkgs {
        inherit system;
        overlays = mkOverlays system;
      };

      homeDirectory = if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

      resolved = {
        inherit hostname;
        isDesktop = false;
        git = { };
        llm = { };
        theme = { };
        darwin = { };
        environment = { };
      }
      // values
      // {
        user = (values.user or { }) // {
          inherit username;
        };
      };
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {
        inherit inputs profile theme;
        values = resolved;
      };

      # The same list the two host wrappers import, minus the platform trees.
      # `modules/darwin/home` and `modules/nixos/home` need an `osConfig` that
      # does not exist here.
      modules = [
        ../../modules/shared/options/theme.nix
        ../../modules/home/programs/llm/options.nix
        ../../modules/home/programs/git/options.nix
        ../../modules/home
        {
          home = {
            inherit username homeDirectory;
          };

          sysinit = {
            git = resolved.git;
            llm = resolved.llm;
            theme = resolved.theme;
          };
        }
      ];
    };
}
