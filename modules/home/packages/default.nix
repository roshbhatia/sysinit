{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:
{
  imports = [
    (import ./nixpkgs {
      inherit config values pkgs;
    })
    (import ./cargo {
      inherit lib values utils;
    })
    (import ./gh {
      inherit lib values utils;
    })
    (import ./go {
      inherit lib values utils;
    })
    (import ./kubectl {
      inherit lib values utils;
    })
    (import ./node {
      inherit lib values utils;
    })
    (import ./python {
      inherit lib values utils;
    })
  ];
}
