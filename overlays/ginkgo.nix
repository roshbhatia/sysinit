{ }:

final: prev: {
  ginkgo = prev.ginkgo.overrideAttrs (_old: {
    doCheck = false;
  });
}
