{ lib }:
# Reading the active palette without requiring stylix to be there.
#
# On a box with no stylix module, `config.lib.stylix.colors` is an evaluation error
# rather than a missing colour, so thirteen readers go through one accessor. A
# library and not an option: some callers are `let` bindings.
let
  # Base16 default dark, written down rather than fetched: the fallback exists for a
  # box with neither stylix nor `pkgs.base16-schemes`. Deliberately not this
  # repository's own theme, which would be a second place it is written down.
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

  # The key shape stylix hands out. Only the plain name and the three `-rgb-*`
  # channels, which are what this repository reads. A missing-attribute error naming
  # the key is the signal to add it here.
  channel = value: offset: lib.fromHexString (lib.substring offset 2 value);

  expand = name: value: {
    "${name}" = value;
    "${name}-rgb-r" = channel value 0;
    "${name}-rgb-g" = channel value 2;
    "${name}-rgb-b" = channel value 4;
  };

  fallback = lib.foldl' (acc: name: acc // expand name hex.${name}) {
    # `fastfetch.nix` prints the scheme name, so the fallback needs one of its own.
    scheme = "Base16 Default Dark";
  } (lib.attrNames hex);
in
{
  inherit fallback;

  # `or` catches a missing level anywhere in the path: stylix disabled, `lib.stylix`
  # undefined, or the module never imported.
  colorsOf = config: config.lib.stylix.colors or fallback;

  # Two conditions: `sysinit.theme.enable` is the owner's choice, `stylix.enable` is
  # whether anything computes a palette. Themed output needs both.
  enabled = config: (config.sysinit.theme.enable or true) && (config.stylix.enable or false);
}
