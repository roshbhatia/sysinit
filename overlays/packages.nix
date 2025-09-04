{
  inputs,
  system,
  ...
}:

_final: _prev: {
  firefox-addons = inputs.firefox-addons.packages.${system};
}
