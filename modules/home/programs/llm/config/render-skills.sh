#!/usr/bin/env bash
# Renders the skill sources into one tree per harness, without Nix.
#
# This is the whole point of moving skill bodies out of Nix strings: a body is
# prose with no store dependency, so an edit should not cost a rebuild. Home
# Manager runs this at activation and the owner runs it directly; a flake check
# asserts both produce the same bytes.
#
# It MUST NOT invoke nix. If it did, the fast path would be the slow path again.
#
# The render is not a copy. Per harness it selects the frontmatter keys that
# harness accepts, injects the RFC 2119 preamble once, and substitutes the
# vocabulary placeholders. Amp validates frontmatter against a fixed allowlist
# and errors on any key outside it, which is why `model` and `effort` are
# claude-only.

set -euo pipefail

SRC="${SYSINIT_SKILL_SRC:?SYSINIT_SKILL_SRC must name the skill source directory}"
OUT="${SYSINIT_SKILL_OUT:-${XDG_STATE_HOME:-$HOME/.local/state}/sysinit/llm/skills}"
SHARED="$SRC/_shared"

PREAMBLE='> Normative keywords follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119); "never" is MUST NOT, "always" is MUST, "prefer" is SHOULD.'

die() {
  echo "render-skills: $*" >&2
  exit 1
}

# One concept, one word per harness. Mirrors lib/vocab.nix; the flake check
# fails if the two disagree.
vocab_agent() { [ "$1" = claude ] && echo teammate || echo subagent; }
vocab_agents() { [ "$1" = claude ] && echo teammates || echo subagents; }
sentence_case() { printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'; }

# Expand `<!-- include: <file> [k=v ...] -->`, substituting {{k}} in the
# fragment. Same grammar as lib/frontmatter.nix.
expand_includes() {
  local name="$1" line file args frag
  while IFS= read -r line; do
    if [[ $line =~ ^\<!--\ include:\ ([^\ ]+)(.*)\ --\>$ ]]; then
      file="${BASH_REMATCH[1]}"
      args="${BASH_REMATCH[2]}"
      [ -f "$SHARED/$file" ] || die "skill '$name': include names a missing fragment: $file"
      frag="$(cat "$SHARED/$file")"
      local pair k v
      for pair in $args; do
        [[ $pair == *=* ]] || die "skill '$name': include argument is not k=v: $pair"
        k="${pair%%=*}"
        v="${pair#*=}"
        frag="${frag//\{\{$k\}\}/$v}"
      done
      printf '%s\n' "$frag"
    else
      printf '%s\n' "$line"
    fi
  done
}

# Flat `key: value` until the closing fence. A key cannot contain a colon, so
# the first `: ` splits and a description keeps its own colons.
fm_get() {
  awk -v want="$1" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm {
      i = index($0, ": ")
      if (i > 0 && substr($0, 1, i - 1) == want) { print substr($0, i + 2); exit }
    }' "$2"
}

body_of() {
  awk 'NR == 1 && $0 == "---" { infm = 1; next }
       infm && $0 == "---" { infm = 0; started = 1; next }
       started && !printed && $0 == "" { printed = 1; next }
       !infm { print }' "$1"
}

render_one() {
  local harness="$1" name="$2" src="$3" dest="$4"
  local desc tools when model effort dmi
  desc="$(fm_get description "$src")"
  [ -n "$desc" ] || die "skill '$name': no description in frontmatter"
  tools="$(fm_get allowed-tools "$src")"
  when="$(fm_get when_to_use "$src")"
  model="$(fm_get model "$src")"
  effort="$(fm_get effort "$src")"
  dmi="$(fm_get disable-model-invocation "$src")"

  {
    echo "---"
    echo "name: $name"
    echo "description: $desc"
    [ -n "$tools" ] && echo "allowed-tools: $tools"
    [ -n "$when" ] && echo "when_to_use: $when"
    if [ "$harness" = claude ]; then
      [ -n "$model" ] && echo "model: $model"
      [ -n "$effort" ] && echo "effort: $effort"
    fi
    [ -n "$dmi" ] && echo "disable-model-invocation: true"
    echo "---"
    echo
    echo "$PREAMBLE"
    echo
    body_of "$src" | expand_includes "$name"
  } > "$dest.tmp"

  local a as
  a="$(vocab_agent "$harness")"
  as="$(vocab_agents "$harness")"
  sed -e "s/{{agent}}/$a/g" -e "s/{{agents}}/$as/g" \
    -e "s/{{Agent}}/$(sentence_case "$a")/g" -e "s/{{Agents}}/$(sentence_case "$as")/g" \
    "$dest.tmp" > "$dest"
  rm -f "$dest.tmp"

  if grep -qE '\{\{[a-zA-Z_]+\}\}' "$dest"; then
    die "skill '$name': rendered output still contains a {{placeholder}}"
  fi
}

main() {
  [ -d "$SRC" ] || die "source directory does not exist: $SRC"
  local staged="$OUT.staging.$$"
  rm -rf "$staged"
  local harness name dir
  for harness in claude amp; do
    for dir in "$SRC"/*/; do
      name="$(basename "$dir")"
      case "$name" in _*) continue ;; esac
      [ -f "$dir/SKILL.md" ] || continue
      mkdir -p "$staged/$harness/$name"
      render_one "$harness" "$name" "$dir/SKILL.md" "$staged/$harness/$name/SKILL.md"
      # Helper scripts and references ship beside the body, executable bit kept.
      local sub
      for sub in "$dir"*/; do
        [ -d "$sub" ] || continue
        case "$(basename "$sub")" in
          references | scripts)
            mkdir -p "$staged/$harness/$name/$(basename "$sub")"
            cp -p "$sub"* "$staged/$harness/$name/$(basename "$sub")/" 2> /dev/null || true
            ;;
        esac
      done
    done
  done
  # Swap whole trees, so a reader never sees a half-written skill set.
  mkdir -p "$(dirname "$OUT")"
  rm -rf "$OUT.old"
  [ -e "$OUT" ] && mv "$OUT" "$OUT.old"
  mv "$staged" "$OUT"
  rm -rf "$OUT.old"
  echo "render-skills: $(find "$OUT/claude" -name SKILL.md | wc -l | tr -d ' ') skills -> $OUT" >&2
}

main "$@"
