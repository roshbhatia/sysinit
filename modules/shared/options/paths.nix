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
  };

  config.home.file.${manifestRelative}.source = manifest;
}
