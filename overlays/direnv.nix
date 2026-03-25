{ }:

final: prev: {
  direnv = prev.direnv.overrideAttrs (_old: {
    doCheck = false;
  });
}
