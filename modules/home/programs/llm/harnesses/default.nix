# The module list is the registry, so a harness added there is imported here
# without a second edit.
let
  registry = import ./registry.nix;
in
{
  imports = builtins.attrValues (builtins.mapAttrs (_name: h: h.module) registry);
}
