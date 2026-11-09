{ lib }:
let
  arguments = values: lib.concatMapStringsSep " " builtins.toJSON values;
in
{
  inherit arguments;
  externs =
    pkgs:
    pkgs.writeText "sysinit-externs.nu" (
      lib.concatMapStringsSep "\n"
        (name: ''
          export use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu *
        '')
        [
          "git"
          "nix"
          "docker"
          "cargo"
          "uv"
          "rg"
          "ssh"
          "just"
        ]
      + ''
        export use ${./externs/git.nu} *
        export use ${./externs/tools.nu} *
      ''
    );
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
