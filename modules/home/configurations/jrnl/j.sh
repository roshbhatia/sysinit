#!/usr/bin/env zsh
# shellcheck disable=all

show_help()
            {
  echo "Usage: j [--write|-w [journal] | [--view|-v [journal]] | [--edit|-e [journal]] | [--help|-h]"
  echo "  --write, -w           Write a journal entry"
  echo "  --view, -v [journal]  View a journal (choose if not specified)"
  echo "  --edit, -e [journal]  Edit a journal (choose if not specified)"
  echo "  --help, -h            Show this help message"
}

choose_journal()
                 {
  local journals_json journals journal
  journals_json=$(jrnl --list --format json)
  if command -v jq > /dev/null 2>&1; then
    journals=($(echo "$journals_json" | jq -r '.journals | keys[]'))
  else
    journals=($(echo "$journals_json" | grep -o '"[^"]*": {' | sed 's/\"//g;s/: {//g'))
  fi
  if [[ ${#journals[@]} -eq 0 ]]; then
    echo "No journals found."
    exit 1
  fi
  journal=$(gum choose --header="Choose a journal:" "${journals[@]}")
  echo "$journal"
}

main()
       {
  local cmd journal
  cmd="${1:-}"
  shift
  case "$cmd" in
    --help | -h | "")
      show_help
      exit 0
      ;;
    --write | -w)
      journal="${1:-}"
      if [[ -z "$journal" ]]; then
        journal=$(choose_journal)
      fi
      if [[ -z "$journal" ]]; then
        echo "No journal selected."
        exit 1
      fi
      gum write --show-cursor-line --show-line-numbers --height 25 | jrnl $journal
      exit $?
      ;;
    --view | -v)
      journal="${1:-}"
      if [[ -z "$journal" ]]; then
        journal=$(choose_journal)
      fi
      if [[ -z "$journal" ]]; then
        echo "No journal selected."
        exit 1
      fi
      jrnl "$journal" view
      exit $?
      ;;
    --edit | -e)
      journal="${1:-}"
      if [[ -z "$journal" ]]; then
        journal=$(choose_journal)
      fi
      if [[ -z "$journal" ]]; then
        echo "No journal selected."
        exit 1
      fi
      jrnl --edit "$journal"
      exit $?
      ;;
    *)
      show_help
      exit 1
      ;;
  esac
}

main "$@"
