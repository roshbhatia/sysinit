{ lib }:
let
  arguments = values: lib.concatMapStringsSep " " builtins.toJSON values;
in
{
  inherit arguments;
  externs =
    pkgs:
    let
      registry = import ../llm/harnesses/registry.nix;
      atuinCompletions = pkgs.runCommand "atuin-completions.nu" { } ''
        ${pkgs.atuin}/bin/atuin gen-completions --shell nushell > "$out"
      '';
      harnessExterns = lib.concatMapStringsSep "\n" (h: ''
        # ${h.label}
        @complete external
        export extern ${builtins.toJSON h.command} [...args: string]
      '') (builtins.attrValues registry);
    in
    pkgs.writeText "sysinit-externs.nu" (
      harnessExterns
      +
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
            "codex"
            "claude"
          ]
      + ''
        export use ${atuinCompletions} *
        export use ${./externs/git.nu} *
        export use ${./externs/tools.nu} *
        export use ${./externs/agents.nu} *
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
