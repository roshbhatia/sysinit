{
  config,
  lib,
  pkgs,
  ...
}:
# One owner for every sysinit state path.
#
# Not to be confused with `modules/lib/paths.nix`, which builds the executable
# search path. This file owns where state is written; that one owns where
# programs are found. The names collide and the concerns do not.
#
# The layout lives in `paths-layout.json`, not here, and that split is the whole
# point. Nix reads the template and emits the paths manifest. Phase 9 builds a
# box with no Nix, and there the same template is expanded by substituting
# `$HOME` and nothing else. Two producers of the same paths would be the defect
# this module exists to remove, so there is one producer and two readers of it.
#
# Consumers read the manifest at runtime. Each is allowed exactly one fallback,
# marked `sysinit:documented-default`, reached only when the manifest is absent.
# That fallback is not decoration: on the no-Nix box the manifest may not be
# installed yet, and a consumer with no default cannot resolve a path at all.
let
  inherit (lib) mkOption types;

  layout = builtins.fromJSON (builtins.readFile ./paths-layout.json);

  # The only substitution the template permits, so that the shell expander on a
  # no-Nix box can be a substitution rather than a program.
  expand = builtins.replaceStrings [ "$HOME" ] [ config.home.homeDirectory ];

  resolved = builtins.mapAttrs (_name: value: expand value) layout.paths;

  manifest = pkgs.writeText "sysinit-paths.json" (
    builtins.toJSON {
      inherit (layout) version;
      paths = resolved;
    }
  );

  # `manifest` is the one path a consumer cannot learn from the manifest, so it
  # is the bootstrap constant every consumer hardcodes. Stripping the home
  # prefix here keeps that constant expressible as `$HOME/...` in five languages
  # without any of them re-deriving the layout.
  manifestRelative = lib.removePrefix "${config.home.homeDirectory}/" resolved.manifest;
in
{
  options.sysinit.paths = {
    resolved = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      default = resolved;
      description = "Every sysinit state path, absolute, derived from paths-layout.json.";
    };

    manifestFile = mkOption {
      type = types.path;
      readOnly = true;
      default = manifest;
      description = "The generated paths manifest, for build-time consumers that cannot read it at runtime.";
    };

    manifestRelativePath = mkOption {
      type = types.str;
      readOnly = true;
      default = manifestRelative;
      description = "The paths manifest relative to the home directory, which is the one constant consumers hardcode.";
    };
  };

  # Absolute, not a variable to expand. `repo.go:63-64` records that a process
  # launched from a mux server inherits no session variables, so `XDG_STATE_HOME`
  # is unset in exactly the place the fallback would have to run.
  config.home.file.${manifestRelative}.source = manifest;
}
