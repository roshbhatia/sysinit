{
  pkgs,
  ...
}:
pkgs.runCommand "pi-shell-prefix-loads-aliases-check" { nativeBuildInputs = [ pkgs.bash ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME/.config/zsh"
  printf "alias fromzshrc='echo zshrc'\n" > "$HOME/.zshrc"
  printf "alias fromzshdir='echo zshdir'\n" > "$HOME/.config/zsh/aliases.zsh"

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
