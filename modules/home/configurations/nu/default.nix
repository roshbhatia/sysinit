{
  config,
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./nu.nix {
      inherit
        config
        lib
        values
        ;
    })
  ];
}

