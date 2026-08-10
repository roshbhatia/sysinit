{ lib }:
# The profile tiers, and the one predicate that reads them.
let
  # Ordered, lowest first.
  tiers = [
    "minimal"
    "dev"
    "workstation"
  ];

  index =
    name:
    let
      found = lib.lists.findFirstIndex (t: t == name) null tiers;
    in
    if found == null then
      throw "sysinit: unknown profile ${name}, expected one of ${lib.concatStringsSep ", " tiers}"
    else
      found;
in
{
  inherit tiers;

  # atLeast profile tier: is `tier` included in a host built for `profile`?
  atLeast = profile: tier: index tier <= index profile;

  # forProfile profile groups: concatenate the groups this profile includes.
  forProfile =
    profile: groups:
    let
      unknown = lib.subtractLists tiers (builtins.attrNames groups);
    in
    if unknown != [ ] then
      throw "sysinit: profile group ${lib.concatStringsSep ", " unknown} names no tier"
    else
      lib.concatMap (tier: groups.${tier} or [ ]) (lib.filter (tier: index tier <= index profile) tiers);
}
