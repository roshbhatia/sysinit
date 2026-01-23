{ lib, ... }:
{
  stripHeaders =
    file:
    let
      content = builtins.readFile file;
      lines = lib.splitString "\n" content;
      isHeaderLine =
        line: lib.hasPrefix "#!/usr/bin/env" line || lib.hasPrefix "# shellcheck disable" line;
      nonHeaderLines = builtins.filter (line: !(isHeaderLine line)) lines;
    in
    lib.concatStringsSep "\n" nonHeaderLines;

  aliases = import ./shell/aliases.nix;

  env =
    {
      colors,
      appTheme,
    }:
    import ./shell/env.nix {
      inherit
        lib
        colors
        appTheme
        ;
    };
}
