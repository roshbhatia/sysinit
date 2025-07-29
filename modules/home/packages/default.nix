{
  config,
  lib,
  pkgs,
  values,
  ...
}:
{
  imports = [
    (import ./nixpkgs {
      inherit config values pkgs;
    })
    (import ./cargo {
      inherit lib values;
    })
    (import ./gh {
      inherit lib values;
    })
    (import ./go {
      inherit lib values;
    })
    (import ./kubectl {
      inherit lib values;
    })
    (import ./node {
      inherit lib values;
    })
    (import ./python {
      inherit lib values;
    })
  ];
}

