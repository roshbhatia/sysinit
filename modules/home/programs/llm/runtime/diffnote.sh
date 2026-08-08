usage() {
  printf '%s\n' \
    'Agent review notes on a working-tree diff, rendered by neovim'"'"'s CodeDiff view.' \
    '' \
    'Usage:' \
    '  diffnote add --file <path> --line <n> --summary <text> [--rationale <text>] [--author <name>] [--replace]' \
    '  diffnote apply --stdin' \
    '  diffnote list [--file <path>] [--json]' \
    '  diffnote clear [--file <path>] [--yes]' \
    '  diffnote path'
}

die() {
  printf 'diffnote: %s\n' "$1" >&2
  exit 1
}

need_value() {
  [ "$2" -ge 2 ] || die "$1 needs a value"
}

repo_root() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
    git rev-parse --show-toplevel 2> /dev/null
}

note_file() {
  local root=$1 digest state_home
  digest=$(printf '%s' "$root" | sha256sum | cut -c1-16)
  state_home=${XDG_STATE_HOME:-$HOME/.local/state}
  state_home=${state_home%/}
  printf '%s/agents/diff-notes/%s-%s.json\n' "$state_home" "$(basename "$root")" "$digest"
}

normalize_absolute() {
  local rest=${1#/} result="" segment
  while [ -n "$rest" ]; do
    segment=${rest%%/*}
    if [ "$segment" = "$rest" ]; then
      rest=""
    else
      rest=${rest#*/}
    fi
    case $segment in
      "" | ".") ;;
      "..")
        [ -n "$result" ] || return 1
        result=${result%/*}
        ;;
      *) result="$result/$segment" ;;
    esac
  done
  printf '%s\n' "${result:-/}"
}

relative_to_root() {
  local root=$1 path=$2 base absolute normalized
  case $path in
    /*) absolute=$path ;;
    *)
      base=$(pwd -P) || return 1
      absolute=$base/$path
      ;;
  esac
  normalized=$(normalize_absolute "$absolute") || return 1
  case $normalized in
    "$root") return 1 ;;
    "$root"/*) printf '%s\n' "${normalized#"$root"/}" ;;
    *) return 1 ;;
  esac
}

has_control_bytes() {
  [ "$1" != "$(printf '%s' "$1" | tr -d '[:cntrl:]')" ]
}

store_is_valid() {
  jq -e 'type == "object" and (.notes | type == "array")' "$1" > /dev/null 2>&1
}

ensure_store() {
  local file=$1 root=$2
  mkdir -p "$(dirname "$file")"

  if [ -s "$file" ]; then
    store_is_valid "$file" ||
      die "$file is not a valid note store. Move it aside to start over."
    return
  fi

  jq -n --arg repo "$root" '{version: 1, repo: $repo, notes: []}' > "$file.new"
  mv -f "$file.new" "$file"
}

write_store() {
  local file=$1 tmp
  tmp=$(mktemp "$file.XXXXXX")
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    die "could not buffer the new store; the previous contents are untouched"
  fi
  if ! store_is_valid "$tmp"; then
    rm -f "$tmp"
    die "refusing to publish a malformed store; the previous contents are untouched"
  fi
  if [ -L "$file" ]; then
    local target
    target=$(readlink "$file")
    rm -f "$tmp"
    die "$file is a symlink to $target; write through it or replace the link deliberately"
  fi
  mv -f "$tmp" "$file"
}

with_store_lock() {
  local file=$1
  shift
  local lock="$file.lock" waited=0
  mkdir -p "$(dirname "$file")"
  while ! mkdir "$lock" 2> /dev/null; do
    waited=$((waited + 1))
    [ "$waited" -le 50 ] || die "another diffnote holds $lock; remove it if it is stale"
    sleep 0.1
  done
  # shellcheck disable=SC2064  # expand $lock now: it must not depend on later state
  trap "rmdir '$lock' 2> /dev/null; exit 1" EXIT
  "$@"
  trap - EXIT
  rmdir "$lock" 2> /dev/null || true
}

SANITIZE='def clean:
            if type == "string"
            then (split("\n") | map(gsub("[[:cntrl:]]"; "")) | join("\n"))
            else . end;
          def oneline:
            if type == "string"
            then (gsub("\n"; " ") | gsub("[[:cntrl:]]"; ""))
            else . end;'

cmd_add() {
  local file="" line="" summary="" rationale="" author="agent" replace=false
  while [ $# -gt 0 ]; do
    case $1 in
      --replace)
        replace=true
        shift
        ;;
      --file)
        need_value --file $#
        file=$2
        shift 2
        ;;
      --line)
        need_value --line $#
        line=$2
        shift 2
        ;;
      --summary)
        need_value --summary $#
        summary=$2
        shift 2
        ;;
      --rationale)
        need_value --rationale $#
        rationale=$2
        shift 2
        ;;
      --author)
        need_value --author $#
        author=$2
        shift 2
        ;;
      *) die "unknown argument for add: $1" ;;
    esac
  done

  [ -n "$file" ] || die "add requires --file"
  ! has_control_bytes "$file" || die "--file must not contain a control byte"
  [ -n "$summary" ] || die "add requires --summary"
  [ -n "$(printf '%s' "$summary" | tr -d '[:cntrl:]')" ] ||
    die "--summary is empty once control bytes are removed"
  case $line in
    "") die "add requires --line" ;;
    *[!0-9]*) die "--line must be a positive integer, got '$line'" ;;
    0*) die "--line must not carry a leading zero, got '$line'" ;;
  esac

  local root store relative
  root=$(repo_root) || die "not inside a git repository"
  relative=$(relative_to_root "$root" "$file") ||
    die "$file does not name a file inside $root"
  store=$(note_file "$root")

  with_store_lock "$store" add_locked "$store" "$root" "$relative" "$line" "$summary" "$rationale" "$author" "$replace"
  printf 'diffnote: %s:%s\n' "$relative" "$line"
}

add_locked() {
  local store=$1 root=$2 relative=$3 line=$4 summary=$5 rationale=$6 author=$7 replace=$8
  ensure_store "$store" "$root"
  jq "$SANITIZE"'
    .notes = ((if $replace
               then (.notes | map(select(.file != $file
                                         or .line != $line
                                         or .author != ($author | oneline))))
               else .notes end)
              + [{
      file: $file,
      line: $line,
      summary: ($summary | oneline),
      rationale: (if $rationale == "" then null else ($rationale | clean) end),
      author: ($author | oneline)
    }])' \
    --arg file "$relative" \
    --argjson line "$line" \
    --arg summary "$summary" \
    --arg rationale "$rationale" \
    --arg author "$author" \
    --argjson replace "$replace" \
    "$store" | write_store "$store"
}

cmd_apply() {
  local stdin=false
  while [ $# -gt 0 ]; do
    case $1 in
      --stdin)
        stdin=true
        shift
        ;;
      *) die "unknown argument for apply: $1" ;;
    esac
  done
  [ "$stdin" = true ] || die "apply reads its batch from stdin; pass --stdin"

  local root store payload normalized count
  root=$(repo_root) || die "not inside a git repository"
  store=$(note_file "$root")

  payload=$(cat)
  printf '%s' "$payload" | jq -e . > /dev/null 2>&1 || die "stdin is not valid JSON"

  normalized=$(printf '%s' "$payload" | jq -c "$SANITIZE"'
    [ (.comments // .notes // [])[]
      | { file: (.file // .filePath),
          line: (.line // .newLine // .oldLine),
          side: (if (.line // .newLine) then "modified"
                 elif .oldLine then "original"
                 else null end),
          summary: (.summary | oneline),
          rationale: (if (.rationale // null) == null then null else (.rationale | clean) end),
          author: ((.author // "agent") | oneline) } ]
  ') || die "could not read the batch"

  count=$(printf '%s' "$normalized" | jq 'length')
  [ "$count" -gt 0 ] || die "batch carried no notes"

  printf '%s' "$normalized" | jq -e 'all(.side == "modified")' > /dev/null 2>&1 ||
    die "a note names only oldLine. Notes anchor on the modified side; pass newLine."
  printf '%s' "$normalized" | jq -e 'all(
    (.file | type == "string" and length > 0)
    and (.line | type == "number" and . >= 1 and (floor == .))
    and (.summary | type == "string" and length > 0)
    and (.author | type == "string")
    and ((.rationale == null) or (.rationale | type == "string"))
  )' > /dev/null 2>&1 ||
    die "every item needs a string file, an integral line of 1 or more, a non-empty summary, a string author, and a string or null rationale"

  while IFS= read -r candidate; do
    ! has_control_bytes "$candidate" || die "a note's file contains a control byte"
  done <<< "$(printf '%s' "$normalized" | jq -r '.[].file')"

  local paths
  paths=$(
    printf '%s' "$normalized" | jq -r '.[].file' | while IFS= read -r candidate; do
      relative_to_root "$root" "$candidate" || exit 1
    done | jq -R -s 'split("\n") | map(select(length > 0))'
  ) || die "a note names a path that is not a file inside $root"

  [ "$(printf '%s' "$paths" | jq 'length')" -eq "$count" ] ||
    die "a note names a path that is not a file inside $root"

  with_store_lock "$store" apply_locked "$store" "$root" "$normalized" "$paths" "$count"
  printf 'diffnote: applied %s note(s)\n' "$count"
}

apply_locked() {
  local store=$1 root=$2 normalized=$3 paths=$4 count=$5
  ensure_store "$store" "$root"
  jq --argjson batch "$normalized" --argjson paths "$paths" '
    .notes += [ range(0; $batch | length)
                | $batch[.] + {file: $paths[.]} | del(.side) ]
  ' "$store" | write_store "$store"
}

cmd_list() {
  local filter="" as_json=false
  while [ $# -gt 0 ]; do
    case $1 in
      --file)
        need_value --file $#
        filter=$2
        shift 2
        ;;
      --json)
        as_json=true
        shift
        ;;
      *) die "unknown argument for list: $1" ;;
    esac
  done

  local root store notes
  root=$(repo_root) || die "not inside a git repository"
  store=$(note_file "$root")
  if [ ! -s "$store" ]; then
    [ "$as_json" = false ] || jq -n --arg repo "$root" '{version: 1, repo: $repo, notes: []}'
    return 0
  fi
  store_is_valid "$store" || die "$store is not a valid note store"

  if [ -n "$filter" ]; then
    local relative
    relative=$(relative_to_root "$root" "$filter") ||
      die "$filter does not name a file inside $root"
    notes=$(jq -c --arg file "$relative" '[.notes[] | select(.file == $file)]' "$store")
  else
    notes=$(jq -c '.notes' "$store")
  fi

  if [ "$as_json" = true ]; then
    printf '%s' "$notes" | jq --arg repo "$root" '{version: 1, repo: $repo, notes: .}'
    return
  fi
  printf '%s' "$notes" | jq -r "$SANITIZE"'.[] | "\(.file):\(.line)  \(.summary | oneline)"'
}

cmd_clear() {
  local filter="" confirmed=false
  while [ $# -gt 0 ]; do
    case $1 in
      --file)
        need_value --file $#
        filter=$2
        shift 2
        ;;
      --yes)
        confirmed=true
        shift
        ;;
      *) die "unknown argument for clear: $1" ;;
    esac
  done

  local root store
  root=$(repo_root) || die "not inside a git repository"
  store=$(note_file "$root")
  [ -s "$store" ] || return 0
  store_is_valid "$store" || die "$store is not a valid note store"

  if [ -n "$filter" ]; then
    local relative
    relative=$(relative_to_root "$root" "$filter") ||
      die "$filter does not name a file inside $root"
    with_store_lock "$store" clear_locked "$store" "$relative"
    printf 'diffnote: cleared notes on %s\n' "$relative"
    return
  fi

  [ "$confirmed" = true ] || die "clearing every note needs --yes"
  with_store_lock "$store" clear_locked "$store" ""
  printf 'diffnote: cleared every note\n'
}

clear_locked() {
  local store=$1 relative=$2
  if [ -n "$relative" ]; then
    jq --arg file "$relative" '.notes |= map(select(.file != $file))' "$store" | write_store "$store"
  else
    jq '.notes = []' "$store" | write_store "$store"
  fi
}

cmd_path() {
  local root
  root=$(repo_root) || die "not inside a git repository"
  note_file "$root"
}

case ${1:-} in
  add)
    shift
    cmd_add "$@"
    ;;
  apply)
    shift
    cmd_apply "$@"
    ;;
  list)
    shift
    cmd_list "$@"
    ;;
  clear)
    shift
    cmd_clear "$@"
    ;;
  path)
    shift
    cmd_path "$@"
    ;;
  -h | --help | help | "")
    usage
    ;;
  *)
    die "unknown subcommand '$1'"
    ;;
esac
