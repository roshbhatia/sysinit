{
  lib,
  profile ? "workstation",
  ...
}:
# What a host is FOR, in one word.
#
# Three tiers, each containing the one below it. A `dev` box has everything
# `minimal` has; a `workstation` has everything `dev` has. Nothing is subtracted
# by moving up, so a package can be placed once, at the lowest tier that needs
# it, instead of being listed per host.
#
#   minimal      a box reached over ssh. A shell, a pager, an editor, git.
#   dev          the above plus the toolchains and the agent runtime.
#   workstation  the above plus what only makes sense in front of a screen.
#
# # Why the selector is not this option
#
# This option is a READER of `profile`, not its owner. `profile` arrives as a
# specialArg, and it has to, because the thing that most needs it is an
# `imports` list.
#
# `imports` is resolved before `config` exists. An `imports` entry that read
# `config.sysinit.profiles.dev.enable` would be infinite recursion: resolving the
# module set requires the option, and the option is defined by the module set.
# Wrapping each module's body in `lib.mkIf` avoids the recursion and defeats the
# purpose, because the module is still imported and still evaluated. Only its
# output is discarded, so nothing is saved.
#
# So the selector is a function argument and this option is derived from it. A
# host still sets one value in one place, `hosts/default.nix`, and everything
# else reads one of the two faces of it: an `imports` list reads `profile`,
# ordinary `config` reads this option.
let
  inherit (lib) mkOption types;

  tiers = [
    "minimal"
    "dev"
    "workstation"
  ];

  # A tier is on when the selected profile is it or anything above it. Written
  # as a position comparison rather than a per-tier condition, so adding a tier
  # is one list entry and not three more booleans that can disagree.
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
