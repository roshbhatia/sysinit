# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
# Parse gate for the zsh fragments `modules/home/programs/zsh/default.nix`
# interpolates into `programs.zsh.initContent`. Nothing else reads them
# before they reach a live shell, so a syntax error ships green and then
# breaks every new shell at once.
# Pi prepends `shellCommandPrefix` to every bash command it runs, so an
# alias from the owner's zsh config resolves inside the harness. The
# property that matters is that BASH PARSES it into commands that load an
# alias, which no assertion over the string can establish: a line-count
# gate passes a backslash-continuation version, which bash reads as one
# command with `eval` as an argument, and rejects a correct
# semicolon-separated one-liner. So run it.
pkgs.runCommand "pi-shell-prefix-loads-aliases-check" { nativeBuildInputs = [ pkgs.bash ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME/.config/zsh"
  printf "alias fromzshrc='echo zshrc'\n" > "$HOME/.zshrc"
  printf "alias fromzshdir='echo zshdir'\n" > "$HOME/.config/zsh/aliases.zsh"

  # Exactly what pi does: the prefix, then the command, in one bash -c.
  got="$(bash -c "$(cat ${../modules/home/programs/llm/harnesses/pi/shell-prefix.sh})
    alias fromzshrc > /dev/null 2>&1 && echo zshrc-ok
    alias fromzshdir > /dev/null 2>&1 && echo zshdir-ok" 2>&1)" || true

  fail=0
  case "$got" in
    *zshrc-ok*) ;;
    *) echo "FAIL: the prefix did not load an alias from ~/.zshrc; bash saw: $got" >&2; fail=1 ;;
  esac
  case "$got" in
    *zshdir-ok*) ;;
    *) echo "FAIL: the prefix did not load an alias from ~/.config/zsh; bash saw: $got" >&2; fail=1 ;;
  esac

  [ "$fail" -eq 0 ] || exit 1
  echo "OK: pi's shell prefix loads aliases from both sources" | tee "$out"
''
