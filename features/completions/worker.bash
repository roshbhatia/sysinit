_sysinit_worker_complete() {
  local current previous
  current="${COMP_WORDS[COMP_CWORD]}"
  previous="${COMP_WORDS[COMP_CWORD - 1]}"
  case "$previous" in
    -w | --wait | -b | --wait-blocked | -t | --tail | -n | --name | --release) return ;;
  esac
  if [[ "$current" == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W '--wait --wait-blocked --tail --name --status --close --release --force --help' -- "$current")
  else
    mapfile -t COMPREPLY < <(compgen -c -- "$current")
  fi
}
complete -F _sysinit_worker_complete worker
