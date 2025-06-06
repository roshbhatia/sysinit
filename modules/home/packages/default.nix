{
  config,
  lib,
  pkgs,
  overlay,
  ...
}:
{
  imports = [
    (import ./nixpkgs {
      inherit config overlay pkgs;
    })
    (import ./cargo {
      inherit lib overlay;
    })
    (import ./gh {
      inherit lib overlay;
    })
    (import ./go {
      inherit lib overlay;
    })
    (import ./kubectl {
      inherit lib overlay;
    })
    (import ./node {
      inherit lib overlay;
    })
    (import ./python {
      inherit lib overlay;
    })
  ];
}

