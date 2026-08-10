#!/usr/bin/env bash

set -euo pipefail

SRC="${SYSINIT_SKILL_SRC:?SYSINIT_SKILL_SRC must name the skill source directory}"
# Read one path out of the paths manifest.
# sysinit:documented-default
sysinit_state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
sysinit_manifest="${SYSINIT_PATHS_MANIFEST:-$sysinit_state_root/sysinit/paths.json}"

sysinit_path() {
  [ -s "$sysinit_manifest" ] || return 1
  command -v jq > /dev/null 2>&1 || return 1
  sp_value=$(jq -er --arg k "$1" '.paths[$k] // empty' "$sysinit_manifest" 2> /dev/null) || return 1
  [ -n "$sp_value" ] || return 1
  printf '%s\n' "$sp_value"
}

OUT="${SYSINIT_SKILL_OUT:-$(sysinit_path llmSkills)}"
: "${OUT:?the paths manifest has no llmSkills entry and SYSINIT_SKILL_OUT is unset}"
SHARED="$SRC/_shared"

PREAMBLE='> Normative keywords follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119); "never" is MUST NOT, "always" is MUST, "prefer" is SHOULD.'

die() {
  echo "render-skills: $*" >&2
  exit 1
}

vocab_agent() { [ "$1" = claude ] && echo teammate || echo subagent; }
vocab_agents() { [ "$1" = claude ] && echo teammates || echo subagents; }
sentence_case() { printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'; }

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
  mkdir -p "$(dirname "$OUT")"
  rm -rf "$OUT.old"
  [ -e "$OUT" ] && mv "$OUT" "$OUT.old"
  mv "$staged" "$OUT"
  rm -rf "$OUT.old"
  echo "render-skills: $(find "$OUT/claude" -name SKILL.md | wc -l | tr -d ' ') skills -> $OUT" >&2
}

main "$@"
