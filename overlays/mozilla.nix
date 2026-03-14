{ inputs, ... }:

if inputs ? nixpkgs-mozilla then
  (import inputs.nixpkgs-mozilla)
else
  _final: _prev: { }
