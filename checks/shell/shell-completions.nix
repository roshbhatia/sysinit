{ pkgs }:
let
  completions =
    builtins.head
      (import ../../features/completions/home.nix { inherit pkgs; }).home.packages;
in
(import ../lib/native.nix { inherit pkgs; }) {
  name = "shell-completions-test";
  inputs = [
    pkgs.bashInteractive
    pkgs.zsh
    pkgs.fish
  ];
  environment.COMPLETION_ROOT = completions;
  commands = [
    [
      "bash"
      "-c"
      ''

        source "$COMPLETION_ROOT/share/bash-completion/completions/worker.bash"
        COMP_WORDS=(worker --sta)
        COMP_CWORD=1
        _sysinit_worker_complete
        [[ "''${COMPREPLY[*]}" == --status ]]

      ''
    ]
    [
      "zsh"
      "-c"
      ''

        fpath=("$COMPLETION_ROOT/share/zsh/site-functions" $fpath)
        autoload -Uz compinit
        compinit -d "$HOME/.zcompdump"
        [[ $_comps[ere] == _ere && $_comps[worker] == _worker && $_comps[sgg] == _sgg ]]

      ''
    ]
    [
      "fish"
      "-c"
      ''

        source "$COMPLETION_ROOT/share/fish/vendor_completions.d/worker.fish"
        complete --do-complete="worker --sta" | string match -q -- "--status*"

      ''
    ]
    [
      "nu"
      "--no-config-file"
      "-c"
      ''

        source ${completions}/share/nushell/vendor/autoload/worker.nu
        if (scope externs | where name == worker | is-empty) { error make {msg: "Missing Worker completion"} }

      ''
    ]
    [
      "nu"
      "--no-config-file"
      "${./shell-completions.nu}"
      "${completions}"
    ]
  ];
}
