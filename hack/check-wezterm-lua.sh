#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tree="${repo_root}/modules/home/programs/wezterm/lua"

if ! command -v luac > /dev/null 2>&1 || ! command -v lua > /dev/null 2>&1; then
  echo "check-wezterm-lua: lua is not on PATH, skipping" >&2
  exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

status=0

# Every global the tree reads, against the Lua standard library. A local that was
# deleted, renamed, or misspelled compiles clean and evaluates to nil, so no parse
# check can see it. The bytecode can: a global read is `GETTABUP _ENV "name"`.
cat > "$work/allowed" << 'ALLOWED'
_G
error
io
ipairs
load
math
os
package
pairs
pcall
require
setmetatable
string
table
tonumber
tostring
type
ALLOWED
sort -o "$work/allowed" "$work/allowed"

find "$tree" -name '*.lua' -print0 | while IFS= read -r -d '' f; do
  luac -l -l "$f" |
    grep -o '_ENV "[a-zA-Z_][a-zA-Z0-9_]*"' |
    sed 's/_ENV "//; s/"$//'
done | sort -u > "$work/seen"

extra="$(comm -23 "$work/seen" "$work/allowed")"
if [[ -n ${extra} ]]; then
  echo "check-wezterm-lua: the tree reads globals that Lua does not provide:" >&2
  # shellcheck disable=SC2086 # one name per line is the point
  printf '  %s\n' $extra >&2
  echo "Each one is a local that was deleted, renamed, or misspelled." >&2
  status=1
fi

# `sysinit.pkg.ui.rollup`'s precedence rule, exercised without a GUI. `reduce`
# reaches neither stub, so the real module files run unmodified.
cat > "$work/rollup-test.lua" << 'SUITE'
local root = arg[1]
package.path = root .. "/?.lua;" .. package.path
package.preload["wezterm"] = function()
  return { mux = {}, json_parse = function() return nil end }
end
package.preload["sysinit.pkg.utils"] = function()
  return { state_path = function() return "/nonexistent" end }
end

local rollup = require("sysinit.pkg.ui.rollup")

local failures = {}
local function check(cond, msg)
  if not cond then failures[#failures + 1] = msg end
end

local s = rollup.reduce({
  { workspace = "w", status = "working", since = 100 },
  { workspace = "w", status = "waiting", since = 200 },
})
check(s.w.status == "waiting", "higher rank must win: got " .. tostring(s.w.status))
check(s.w.since == 200, "the winner's since must come with it: got " .. tostring(s.w.since))

s = rollup.reduce({
  { workspace = "w", status = "working", since = 300 },
  { workspace = "w", status = "working", since = 100 },
})
check(s.w.since == 100, "on a rank tie the older since must win: got " .. tostring(s.w.since))

s = rollup.reduce({
  { workspace = "w", status = "working", since = 100 },
  { workspace = "w", status = "working" },
})
check(s.w.since == 100, "a nil since must not displace a real one: got " .. tostring(s.w.since))

s = rollup.reduce({
  { workspace = "w", status = "working" },
  { workspace = "w", status = "working", since = 50 },
})
check(s.w.since == 50, "a real since must displace a nil one: got " .. tostring(s.w.since))

s = rollup.reduce({
  { workspace = "w", status = "idle", session = "b" },
  { workspace = "w", status = "idle", session = "a" },
  { workspace = "w", status = "idle", session = "b" },
})
check(#s.w.names == 2, "names must dedup: got " .. tostring(#s.w.names))
check(s.w.names[1] == "b" and s.w.names[2] == "a", "names must keep first-seen order")

s = rollup.reduce({
  { workspace = "one", status = "waiting", since = 1 },
  { workspace = "two", status = "idle", since = 2 },
})
check(s.one.status == "waiting" and s.two.status == "idle", "workspaces must not merge")

s = rollup.reduce({ { workspace = "w", status = "bogus" } })
check(s.w == nil, "an unranked status must not create an entry")

if #failures > 0 then
  for _, f in ipairs(failures) do io.stderr:write("FAIL: " .. f .. "\n") end
  os.exit(1)
end
io.stdout:write("OK: rollup precedence holds\n")
SUITE

suite="$work/rollup-test.lua"
if ! lua "$suite" "$tree" > "$work/out" 2>&1; then
  echo "check-wezterm-lua: the rollup's precedence rule changed." >&2
  cat "$work/out" >&2
  status=1
fi

# One mutant per half of the precedence rule. A substitution that stops matching is
# reported rather than passing silently.
mutate() {
  rm -rf "$work/mutant"
  cp -r "$tree" "$work/mutant"
  chmod -R u+w "$work/mutant"
  local f="$work/mutant/sysinit/pkg/ui/rollup.lua"
  sed -i.bak "s|$1|$2|" "$f" && rm -f "$f.bak"
  if cmp -s "$f" "$tree/sysinit/pkg/ui/rollup.lua"; then
    echo "check-wezterm-lua: mutant '$3' changed nothing; the pattern no longer matches." >&2
    echo "Update hack/check-wezterm-lua.sh to match the current reducer." >&2
    status=1
    return
  fi
  if lua "$suite" "$work/mutant" > "$work/mutant.out" 2>&1; then
    echo "check-wezterm-lua: the suite passed against mutant '$3'." >&2
    echo "A test that passes against a broken reducer is not coverage." >&2
    cat "$work/mutant.out" >&2
    status=1
  fi
}

mutate 'rank > cur.rank' 'rank < cur.rank' 'inverted rank precedence'
mutate 'a < b' 'a > b' 'inverted since tie-break'

if [[ ${status} -eq 0 ]]; then
  echo "check-wezterm-lua: globals are all builtins, and the suite fails against both mutants"
fi
exit "$status"
