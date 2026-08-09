{ lib }:
# The profile tiers, and the one predicate that reads them.
#
# A plain library rather than a module, because its callers are `imports` lists
# and `with pkgs` package lists, neither of which can reach `config`. The option
# face of the same fact is `options/profiles.nix`, and it reads this file so
# there is one list rather than two that can disagree.
let
  # Ordered, lowest first. Each tier contains the one below it.
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
  #
  # A position comparison rather than a condition per tier, so adding a tier is
  # one list entry instead of three more booleans that can disagree.
  atLeast = profile: tier: index tier <= index profile;

  # forProfile profile groups: concatenate the groups this profile includes.
  #
  # Takes an attribute set keyed by tier, so a list is written next to the tier
  # that owns it. A key naming no tier throws rather than being silently
  # dropped, which is the failure mode a typo would otherwise produce: a package
  # group that quietly ships to nobody.
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
