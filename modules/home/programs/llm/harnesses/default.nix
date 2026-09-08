let
  registry = import ./registry.nix;
  wires = [
    "claude-json"
    "exit-code"
    "cursor"
    "none"
  ];
  names = builtins.attrNames registry;
  gateless = builtins.filter (name: !(registry.${name} ? gate)) names;
  badWire = builtins.filter (
    name: registry.${name} ? gate && !(builtins.elem registry.${name}.gate wires)
  ) names;
  missing = "harness registry: no gate wire declared for ${builtins.concatStringsSep ", " gateless}";
  unknown = "harness registry: unknown gate wire on ${builtins.concatStringsSep ", " badWire}";
in
# Every harness answers how the gate dispatcher reaches it, so a new one cannot
# inherit the gap in silence.
assert gateless == [ ] || throw missing;
assert badWire == [ ] || throw unknown;
{
  imports = builtins.attrValues (builtins.mapAttrs (_name: h: h.module) registry);
}
