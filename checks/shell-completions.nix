{ pkgs }:
let
  completions =
    builtins.head
      (import ../modules/home/programs/completions { inherit pkgs; }).home.packages;
in
pkgs.runCommand "shell-completions-test"
  {
    nativeBuildInputs = [
      pkgs.bashInteractive
      pkgs.zsh
      pkgs.fish
      pkgs.nushell
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export COMPLETION_ROOT=${completions}
    bash -c '
      source "$COMPLETION_ROOT/share/bash-completion/completions/worker.bash"
      COMP_WORDS=(worker --sta)
      COMP_CWORD=1
      _sysinit_worker_complete
      [[ "''${COMPREPLY[*]}" == --status ]]
    '
    zsh -c '
      fpath=("$COMPLETION_ROOT/share/zsh/site-functions" $fpath)
      autoload -Uz compinit
      compinit -d "$HOME/.zcompdump"
      [[ $_comps[ere] == _ere && $_comps[worker] == _worker && $_comps[sgg] == _sgg ]]
    '
    fish -c '
      source "$COMPLETION_ROOT/share/fish/vendor_completions.d/worker.fish"
      complete --do-complete="worker --sta" | string match -q -- "--status*"
    '
    nu --no-config-file -c '
      source ${completions}/share/nushell/vendor/autoload/worker.nu
      if (scope externs | where name == worker | is-empty) { error make {msg: "Missing Worker completion"} }
    '
    test -s "$COMPLETION_ROOT/share/bash-completion/completions/ere.bash"
    test -s "$COMPLETION_ROOT/share/fish/vendor_completions.d/ere.fish"
    touch "$out"
  ''
