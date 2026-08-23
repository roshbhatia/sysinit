{
  lib,
  profile ? "workstation",
  ...
}:
let
  inherit (lib) mkOption types;

  tiers = [
    "minimal"
    "dev"
    "workstation"
  ];

  index = name: lib.lists.findFirstIndex (t: t == name) null tiers;

  selected = index profile;

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
