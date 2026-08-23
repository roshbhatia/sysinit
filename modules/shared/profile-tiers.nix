{ lib }:
let
  tiers = [
    "minimal"
    "dev"
    "workstation"
  ];

  index = name: lib.lists.findFirstIndex (t: t == name) null tiers;
in
{
  inherit tiers;

  atLeast = profile: tier: index tier <= index profile;

  forProfile =
    profile: groups:
    lib.concatMap (tier: groups.${tier} or [ ]) (lib.filter (tier: index tier <= index profile) tiers);
}
