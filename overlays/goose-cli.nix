{ }:

final: prev: {
  goose-cli = prev.goose-cli.overrideAttrs (_old: {
    doCheck = false;
  });
}
