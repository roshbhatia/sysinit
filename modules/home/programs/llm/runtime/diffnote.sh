# Agent review notes on a working-tree diff. Write-only from the agent's side;
# neovim's CodeDiff view renders them (see lua/harness/diffnote.lua).
#
# The command surface follows hunk's `session comment` API, which is the shape
# every harness skill already knows: one note with `add`, a batch with
# `apply --stdin`, plus `list` and `clear`. What it does NOT copy is the daemon.
# There is no session to attach to and no socket to find: notes go to one JSON
# file per repository, and the editor watches that file. So `add` works with no
# editor running, and the note is there when the view next opens.
#
# Note text is untrusted: an agent writes it, and what steers that agent includes
# repository content that may not be the owner's. So text is stripped of control
# bytes on the way IN, once, rather than at each of the two places that render it.
#
# Usage:
#   diffnote add --file <path> --line <n> --summary <text> [--rationale <text>]
#                [--author <name>] [--replace]
#   diffnote apply --stdin
#   diffnote list [--file <path>] [--json]
#   diffnote clear [--file <path>] [--yes]
#   diffnote path

# Spelled out rather than read back out of "$0": writeShellApplication wraps this
# body, so the header comment is not at a stable offset in the installed file.
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

# `shift 2` on a flag with no value fails under errexit BEFORE any later
# validation runs, which made every "requires" diagnostic unreachable and exited
# 1 with no message at all.
need_value() {
  [ "$2" -ge 2 ] || die "$1 needs a value"
}

repo_root() {
  # Ambient git environment must not leak in: a hook or `rebase --exec` exports
  # GIT_DIR and GIT_WORK_TREE, and rev-parse would answer about that repo.
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
    git rev-parse --show-toplevel 2> /dev/null
}

# Must match `note_path` in lua/harness/diffnote.lua: <basename>-<sha256[0:16]>.
# `%s` with the trailing slash stripped, because the Lua half joins path segments
# and would collapse a doubled slash that this half would keep.
note_file() {
  local root=$1 digest state_home
  digest=$(printf '%s' "$root" | sha256sum | cut -c1-16)
  state_home=${XDG_STATE_HOME:-$HOME/.local/state}
  state_home=${state_home%/}
  printf '%s/agents/diff-notes/%s-%s.json\n' "$state_home" "$(basename "$root")" "$digest"
}

# Resolve `.` and `..` lexically and collapse repeated slashes. No `realpath`:
# a note may name a file the agent has not created yet. Returns non-zero when the
# path walks above `/`.
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

# Repo-relative, because that is the key the editor renders against. An absolute
# path, a `..` escape, or a path from another directory would silently never match
# a buffer, and a `..` escape also stored a note about a file outside the repo.
#
# `pwd -P` rather than `$PWD`: `rev-parse --show-toplevel` answers with the
# physical path, and on macOS /tmp and $TMPDIR are symlinks, so the logical `$PWD`
# made every relative --file fail as "outside" the repository it was inside.
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

# Rejected rather than stripped: stripping would key the note on a path the caller
# did not name. A real path carries no control byte.
has_control_bytes() {
  # `tr -d`, not `grep '[[:cntrl:]]'`: grep matches within a line, so a NEWLINE is a
  # line separator it can never match, and a newline in a path is the case that
  # forged a whole extra row in `diffnote list`.
  [ "$1" != "$(printf '%s' "$1" | tr -d '[:cntrl:]')" ]
}

store_is_valid() {
  jq -e 'type == "object" and (.notes | type == "array")' "$1" > /dev/null 2>&1
}

ensure_store() {
  local file=$1 root=$2
  mkdir -p "$(dirname "$file")"

  if [ -s "$file" ]; then
    # Non-empty and unparseable: refuse. The notes in it are the owner's, and a
    # silent rebuild would discard them.
    store_is_valid "$file" ||
      die "$file is not a valid note store. Move it aside to start over."
    return
  fi

  # Absent, or zero bytes. A zero-byte file is what an interrupted first write
  # leaves behind, and testing only `-f` made that state absorbing: `jq` on an
  # empty file exits 0 with no output, so every later write reported success and
  # stored nothing, permanently.
  jq -n --arg repo "$root" '{version: 1, repo: $repo, notes: []}' > "$file.new"
  mv -f "$file.new" "$file"
}

# Publish only what parses. `cat > tmp; mv` committed whatever arrived, and the
# producer is upstream in a pipeline, so its failure was observable only after the
# store had already been replaced by a fragment or by nothing at all.
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
  # A symlinked store is the owner's layout choice (state on another volume, say).
  # `mv -f` replaced the link with a regular file and left the target empty.
  if [ -L "$file" ]; then
    local target
    target=$(readlink "$file")
    rm -f "$tmp"
    die "$file is a symlink to $target; write through it or replace the link deliberately"
  fi
  mv -f "$tmp" "$file"
}

# Read-modify-write with no lock was last-write-wins, and the losing run still
# printed success. One lock directory per store, created atomically.
with_store_lock() {
  local file=$1
  shift
  local lock="$file.lock" waited=0
  # Before the loop, not inside `ensure_store`: the lock lives beside the store, so
  # on a first run `mkdir "$lock"` failed for a missing parent and every retry
  # failed the same way, reporting a held lock that never existed.
  mkdir -p "$(dirname "$file")"
  while ! mkdir "$lock" 2> /dev/null; do
    waited=$((waited + 1))
    [ "$waited" -le 50 ] || die "another diffnote holds $lock; remove it if it is stale"
    sleep 0.1
  done
  # `exit 1` after the rmdir, not `|| true`: the trap's last command sets the exit
  # status, so `|| true` made an interrupted write report 0.
  # shellcheck disable=SC2064  # expand $lock now: it must not depend on later state
  trap "rmdir '$lock' 2> /dev/null; exit 1" EXIT
  "$@"
  # Clear the trap FIRST. Between a successful rmdir and `trap - EXIT` another
  # waiter can take the lock, and a signal in that window fired our trap against
  # their lock.
  trap - EXIT
  rmdir "$lock" 2> /dev/null || true
}

# Control bytes are stripped once, here, so neither `list` on a terminal nor the
# editor has to defend itself. A newline survives in `rationale`, which the
# renderer splits into lines, and is folded to a space in `summary`, which is one
# line by contract.
# `[[:cntrl:]]`, not a \uXXXX range: verified that the escaped-range form matched
# the printable bytes and left the control bytes in place, which is the opposite of
# the intent. UTF-8 outside ASCII survives both definitions.
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
      # Drop any existing note with the same file, line, and author before
      # appending. Nothing prunes this store, so a caller that writes on every
      # edit rather than on every review would otherwise grow it without bound
      # and bury the review notes it is meant to sit beside.
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
  # After stripping, not before: a summary of only control bytes passed the -n test
  # and then landed as an empty note, which `apply` refuses for the same input.
  [ -n "$(printf '%s' "$summary" | tr -d '[:cntrl:]')" ] ||
    die "--summary is empty once control bytes are removed"
  # `0*` covers 0, 00, and 0123: jq --argjson normalizes a leading zero, so
  # `--line 00` stored line 0 and `--line 0123` stored line 123.
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
  # The filter runs on the sanitized author, matching what is stored, so a
  # replace still finds the note a previous run wrote.
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

# Batch form. Accepts hunk's payload shape, so a skill that already emits
# `{"comments":[{"filePath","newLine","summary"}]}` needs no rewrite, and also
# accepts this tool's own `{"notes":[{"file","line",...}]}`.
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

  # Validate the whole batch before touching anything, so a bad item cannot leave
  # half a batch applied. `side` is carried so an original-side comment can be
  # refused rather than anchored on the modified side, where its line number names
  # unrelated code.
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
  # `author` and `rationale` are typed here too. `add` guarantees a string and a
  # string-or-null, and `list --json` is a documented output, so the two entry points
  # must not disagree about what a consumer can expect.
  printf '%s' "$normalized" | jq -e 'all(
    (.file | type == "string" and length > 0)
    and (.line | type == "number" and . >= 1 and (floor == .))
    and (.summary | type == "string" and length > 0)
    and (.author | type == "string")
    and ((.rationale == null) or (.rationale | type == "string"))
  )' > /dev/null 2>&1 ||
    die "every item needs a string file, an integral line of 1 or more, a non-empty summary, a string author, and a string or null rationale"

  # Per item, because the shell rejects a control byte rather than stripping it and
  # jq cannot say which item offended. A path is the one text field that must survive
  # verbatim to match a buffer, so it cannot be sanitized in place.
  while IFS= read -r candidate; do
    ! has_control_bytes "$candidate" || die "a note's file contains a control byte"
  done <<< "$(printf '%s' "$normalized" | jq -r '.[].file')"

  # Each path is resolved against the repo root here, not in jq, because only the
  # shell knows the physical cwd and what the caller meant by a relative path.
  # One pass, not one jq per note: the old loop passed a growing accumulator on
  # argv and cost time quadratic in the payload.
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
  # After validation, so a rejected batch never creates a store where none was.
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
  # Text output is re-sanitized on the way out as well as on the way in. A store
  # written by an older build, or edited by hand, is still untrusted input to a
  # terminal, where an escape sequence can clear the screen or hide a line.
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

  # Clearing every note in the repository discards work the owner may still want,
  # so the whole-store form asks. A single file does not.
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
