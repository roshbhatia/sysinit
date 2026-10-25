{ lib }:
let
  arguments = values: lib.concatMapStringsSep " " builtins.toJSON values;
in
{
  inherit arguments;
  completers =
    pkgs:
    builtins.replaceStrings
      [ "@timeout@" "@fish@" "@carapace@" ]
      [ "${pkgs.coreutils}/bin/timeout" "${pkgs.fish}/bin/fish" "${pkgs.carapace}/bin/carapace" ]
      (builtins.readFile ./completers.nu.tmpl);
  pathAdd = paths: "path add ${arguments paths}";

  sourceCompletion = package: name: ''
    source ${builtins.toJSON "${package}/share/nushell/vendor/autoload/${name}.nu"}
  '';
}
