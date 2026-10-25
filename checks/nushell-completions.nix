{
  lib,
  pkgs,
  fzf,
}:
let
  nushellLib = import ../modules/home/programs/nushell/lib.nix { inherit lib; };
  config = pkgs.writeText "completion-check-config.nu" ''
    ${nushellLib.completers pkgs}
  '';
  script = pkgs.writeText "completion-check.nu" ''
    let git = ('git --ver' | commandline complete)
    if not ($git | any {|value| $value | str contains '--version'}) {
      error make {msg: $"fish completion failed: ($git)"}
    }
    let carapace = ('fzf --ver' | commandline complete)
    if not ($carapace | any {|value| $value | str contains '--version'}) {
      error make {msg: $"carapace completion failed: ($carapace)"}
    }
    let path = ('cat completion-tar' | commandline complete)
    if not ($path | any {|value| $value | str contains 'completion-target.txt'}) {
      error make {msg: $"path fallback failed: ($path)"}
    }
    source ${fzf}/share/fzf/completion.nu
    $env.FZF_DEFAULT_OPTS = '--filter=completion-target.txt'
    $env.FZF_COMPLETERS = {cat: {|prefix, spans| glob 'completion-*.txt'}}
    let fuzzy_place = ('cat **' | commandline complete --input | get place)
    let fuzzy = (do $env.config.completions.external.completer $fuzzy_place)
    if not ($fuzzy | any {|value| $value | str contains 'completion-target.txt'}) {
      error make {msg: $"fzf completion failed: ($fuzzy)"}
    }
    source ${fzf}/share/fzf/completion.nu
    let git_place = ('git --ver' | commandline complete --input | get place)
    let repeated = (do $env.config.completions.external.completer $git_place)
    if not ($repeated | any {|item| $item.value == '--version'}) {
      error make {msg: 'reloading fzf changed fallback completion'}
    }
    $env.__fzf_previous_completer = null
    let fallback_place = ('unknown-program completion-tar' | commandline complete --input | get place)
    let fallback = (do $env.config.completions.external.completer $fallback_place)
    if $fallback != {completions: [], fallback: true} {
      error make {msg: $"builtin fallback was not requested: ($fallback)"}
    }
  '';
in
pkgs.runCommand "nushell-completions"
  {
    nativeBuildInputs = [
      pkgs.nushell
      fzf
      pkgs.git
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" "$TMPDIR/fixtures"
    cd "$TMPDIR/fixtures"
    touch completion-target.txt unrelated.txt
    if ! ${pkgs.nushell}/bin/nu --config ${config} ${script} 2> "$TMPDIR/stderr"; then
      cat "$TMPDIR/stderr" >&2
      exit 1
    fi
    if [ -s "$TMPDIR/stderr" ]; then
      cat "$TMPDIR/stderr" >&2
      exit 1
    fi
    touch "$out"
  ''
