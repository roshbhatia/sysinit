{
  config,
  lib,
  pkgs,
  ...
}:
# One owner for every sysinit state path.
let
  inherit (lib) mkOption types;

  layout = builtins.fromJSON (builtins.readFile ./paths-layout.json);

  # The only substitution the template permits, so that the shell expander on a no-Nix
  # box can be a substitution rather than a program.
  expand = builtins.replaceStrings [ "$HOME" ] [ config.home.homeDirectory ];

  resolved = builtins.mapAttrs (_name: value: expand value) layout.paths;

  manifest = pkgs.writeText "sysinit-paths.json" (
    builtins.toJSON {
      inherit (layout) version;
      paths = resolved;
    }
  );

  # `manifest` is the one path a consumer cannot learn from the manifest, so it
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

  # Absolute, not a variable to expand.
  config.home.file.${manifestRelative}.source = manifest;
}
