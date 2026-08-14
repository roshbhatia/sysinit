{ lib }:
let
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

  channel = value: offset: lib.fromHexString (lib.substring offset 2 value);

  expand = name: value: {
    "${name}" = value;
    "${name}-rgb-r" = channel value 0;
    "${name}-rgb-g" = channel value 2;
    "${name}-rgb-b" = channel value 4;
  };

  fallback = lib.foldl' (acc: name: acc // expand name hex.${name}) {
    scheme = "Base16 Default Dark";
  } (lib.attrNames hex);
in
{
  inherit fallback;

  colorsOf = config: config.lib.stylix.colors or fallback;

  enabled = config: (config.sysinit.theme.enable or true) && (config.stylix.enable or false);
}
