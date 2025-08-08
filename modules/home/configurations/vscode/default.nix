{
  values,
  utils,
  ...
}:

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    (import ./vscode.nix {
      inherit
        config
        lib
        values
        pkgs
        utils
        ;
    })
  ];
}
