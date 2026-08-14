let
  registry = import ./registry.nix;
in
{
  imports = builtins.attrValues (builtins.mapAttrs (_name: h: h.module) registry);
}
