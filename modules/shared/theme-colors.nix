{ lib }:
# Reading the active palette without requiring stylix to be there.
#
# Thirteen modules read `config.lib.stylix.colors`. On a box with no stylix
# module that attribute does not exist, and the dereference is an evaluation
# error rather than a missing color, so every one of them has to go through one
# accessor instead of reaching for the attribute themselves.
#
# A library rather than an option, for the same reason `profile-tiers.nix` is
# one: some callers are in `let` bindings evaluated before the module system has
# finished, and all of them want a plain function.
let
  # The palette used when stylix is absent. Base16 default dark, which is the
  # scheme base16 itself ships as its reference.
  #
  # Written down rather than fetched, because the point of the fallback is a box
  # that has neither stylix nor `pkgs.base16-schemes`. A palette that needed a
  # package to resolve would fail in exactly the case it exists for.
  #
  # It is deliberately NOT this repository's own theme. A host without stylix is
  # not making a statement about colors, and copying the owner's scheme here
  # would create a second place it is written down.
  hex = {
    base00 = "181818";
    base01 = "282828";
    base02 = "383838";
    base03 = "585858";
    base04 = "b8b8b8";
    base05 = "d8d8d8";
    base06 = "e8e8e8";
    base07 = "f8f8f8";
    base08 = "ab4642";
    base09 = "dc9656";
    base0A = "f7ca88";
    base0B = "a1b56c";
    base0C = "86c1b9";
    base0D = "7cafc2";
    base0E = "ba8baf";
    base0F = "a16946";
  };

  # The same sixteen colors in the key shape stylix hands out, because a consumer
  # reads `base08` and `base08-rgb-r` from the same attrset and cannot be asked
  # to know which one it got. Only the plain name and the three `-rgb-*` channels
  # are produced: they are what this repository reads, checked by searching the
  # tree for every key taken off the palette. A consumer that starts reading
  # `-hex-r` or `withHashtag` gets a missing-attribute error naming the key, which
  # is the signal to add it here.
  channel = value: offset: lib.fromHexString (lib.substring offset 2 value);

  expand = name: value: {
    "${name}" = value;
    "${name}-rgb-r" = channel value 0;
    "${name}-rgb-g" = channel value 2;
    "${name}-rgb-b" = channel value 4;
  };

  fallback = lib.foldl' (acc: name: acc // expand name hex.${name}) {
    # `fastfetch.nix` prints the scheme's name, so the fallback needs one. It
    # says what it is rather than borrowing the name of a scheme this host is
    # not running.
    scheme = "Base16 Default Dark";
  } (lib.attrNames hex);
in
{
  inherit fallback;

  # colorsOf config: the active base16 palette.
  #
  # `or` catches a missing level anywhere in the path, so this answers whether
  # stylix is disabled, whether `config.lib.stylix` is undefined, or whether the
  # module was never imported. A caller cannot tell the three apart and does not
  # need to.
  colorsOf = config: config.lib.stylix.colors or fallback;

  # enabled config: should this host generate themed output at all?
  #
  # Two conditions, because they answer different questions. `sysinit.theme.enable`
  # is the owner's choice. `stylix.enable` is whether the thing that computes a
  # palette is running. Themed output needs both, and a module that checked only
  # the first would emit the fallback palette as though it were a decision.
  enabled = config: (config.sysinit.theme.enable or true) && (config.stylix.enable or false);
}
