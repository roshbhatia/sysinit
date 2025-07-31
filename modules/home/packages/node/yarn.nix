{
  lib,
  values,
  utils,
  ...
}:

let
  yarnPackages = [
    "mcp-hub@latest"
  ]
  ++ (values.yarn.additionalPackages or [ ]);
in
{
  home.file.".yarnrc" = {
    text = ''
      strict-ssl false
      yarn-offline-mirror ".local/share/yarn/packages-cache"
    '';
  };

  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (utils.sysinit.mkPackageManagerScript "yarn" yarnPackages);
}
