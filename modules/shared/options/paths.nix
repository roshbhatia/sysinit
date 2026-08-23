{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  layout = builtins.fromJSON (builtins.readFile ./paths-layout.json);

  expand = builtins.replaceStrings [ "$HOME" ] [ config.home.homeDirectory ];

  resolved = builtins.mapAttrs (_name: expand) layout.paths;

  manifest = pkgs.writeText "sysinit-paths.json" (
    builtins.toJSON {
      inherit (layout) version;
      paths = resolved;
    }
  );

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

  config.home.file.${manifestRelative}.source = manifest;
}
