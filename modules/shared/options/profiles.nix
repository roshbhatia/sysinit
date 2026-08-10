{
  lib,
  profile ? "workstation",
  ...
}:
# What a host is FOR, in one word. Three additive tiers: minimal (ssh), dev
let
  inherit (lib) mkOption types;

  tiers = [
    "minimal"
    "dev"
    "workstation"
  ];

  # A position comparison, so adding a tier is one list entry.
  index = name: lib.lists.findFirstIndex (t: t == name) null tiers;

  selected =
    if index profile == null then
      throw "sysinit: unknown profile ${profile}, expected one of ${lib.concatStringsSep ", " tiers}"
    else
      index profile;

  enabled = name: index name <= selected;
in
{
  options.sysinit.profiles = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair name {
        enable = mkOption {
          type = types.bool;
          readOnly = true;
          default = enabled name;
          description = "Whether this host is at least a ${name} host. Derived from the `profile` argument, never set directly.";
        };
      }
    ) tiers
  );

  options.sysinit.profile = mkOption {
    type = types.enum tiers;
    readOnly = true;
    default = profile;
    description = "The profile this host selected, as passed through specialArgs.";
  };
}
