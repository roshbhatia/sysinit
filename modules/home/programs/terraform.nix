{
  config,
  lib,
  ...
}:
let
  terraformCache = "${config.xdg.cacheHome}/terraform/plugin-cache";
  opentofuCache = "${config.xdg.cacheHome}/opentofu/plugin-cache";
in
{
  home = {
    file = {
      ".terraformrc".text = ''
        plugin_cache_dir = ${builtins.toJSON terraformCache}
      '';

      ".tofurc".text = ''
        plugin_cache_dir = ${builtins.toJSON opentofuCache}
      '';
    };

    activation.providerPluginCaches = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${
        lib.escapeShellArgs [
          terraformCache
          opentofuCache
        ]
      }
    '';
  };
}
