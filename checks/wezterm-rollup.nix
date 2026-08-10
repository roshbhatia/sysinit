{
  pkgs,
  ...
}:
# `sysinit.pkg.ui.rollup`'s precedence rule, exercised without a GUI.
#
# The rollup collapses every agent pane in the mux to one entry per workspace.
# Which pane wins is the whole behavior, and it had no coverage: the tab bar,
# the chips, and the session tree all render from it, and a wrong winner reaches
# the owner as a wrong badge rather than as a failing check.
#
# The module splits the walk from the collapse for this reason. `collect` needs
# a live mux and cannot run here. `reduce` is a pure function of `collect`'s
# output, so this check feeds it observation tables directly.
#
# It also runs the test against two MUTANTS and requires both to fail. A test
# that passes against a broken reducer is not coverage, and the only way to keep
# that true is to break the reducer on every run rather than once by hand.
let
  # Lua 5.4 because that is what wezterm embeds. `wezterm` and
  # `sysinit.pkg.utils` are stubbed: `reduce` reaches neither, and preloading
  # them keeps the real module files unmodified.
  suite = pkgs.writeText "rollup-test.lua" ''
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

    -- Higher rank wins, regardless of walk order.
    local s = rollup.reduce({
      { workspace = "w", status = "working", since = 100 },
      { workspace = "w", status = "waiting", since = 200 },
    })
    check(s.w.status == "waiting", "higher rank must win: got " .. tostring(s.w.status))
    check(s.w.since == 200, "the winner's since must come with it: got " .. tostring(s.w.since))

    -- Same rank: the older pane wins, so a badge does not flicker between two
    -- panes in the same state.
    s = rollup.reduce({
      { workspace = "w", status = "working", since = 300 },
      { workspace = "w", status = "working", since = 100 },
    })
    check(s.w.since == 100, "on a rank tie the older since must win: got " .. tostring(s.w.since))

    -- A pane with no timestamp never displaces one that has it.
    s = rollup.reduce({
      { workspace = "w", status = "working", since = 100 },
      { workspace = "w", status = "working" },
    })
    check(s.w.since == 100, "a nil since must not displace a real one: got " .. tostring(s.w.since))

    -- The reverse: a timestamp does displace the absence of one.
    s = rollup.reduce({
      { workspace = "w", status = "working" },
      { workspace = "w", status = "working", since = 50 },
    })
    check(s.w.since == 50, "a real since must displace a nil one: got " .. tostring(s.w.since))

    -- Session names dedup, first seen first.
    s = rollup.reduce({
      { workspace = "w", status = "idle", session = "b" },
      { workspace = "w", status = "idle", session = "a" },
      { workspace = "w", status = "idle", session = "b" },
    })
    check(#s.w.names == 2, "names must dedup: got " .. tostring(#s.w.names))
    check(s.w.names[1] == "b" and s.w.names[2] == "a", "names must keep first-seen order")

    -- Workspaces are separate groups and never collapse into each other.
    s = rollup.reduce({
      { workspace = "one", status = "waiting", since = 1 },
      { workspace = "two", status = "idle", since = 2 },
    })
    check(s.one.status == "waiting" and s.two.status == "idle", "workspaces must not merge")

    -- A status outside the rank table produces no entry rather than an error.
    s = rollup.reduce({ { workspace = "w", status = "bogus" } })
    check(s.w == nil, "an unranked status must not create an entry")

    if #failures > 0 then
      for _, f in ipairs(failures) do io.stderr:write("FAIL: " .. f .. "\n") end
      os.exit(1)
    end
    io.stdout:write("OK: " .. "rollup precedence holds\n")
  '';
in
pkgs.runCommand "wezterm-rollup-check"
  {
    nativeBuildInputs = [ pkgs.lua5_4 ];
    src = ../modules/home/programs/wezterm/lua;
    inherit suite;
  }
  ''
    tree="$TMPDIR/lua"
    cp -r "$src" "$tree"
    chmod -R u+w "$tree"

    if ! lua "$suite" "$tree" > "$TMPDIR/out" 2>&1; then
      echo "FAIL: the rollup's precedence rule changed." >&2
      cat "$TMPDIR/out" >&2
      exit 1
    fi
    cat "$TMPDIR/out"

    # Each mutant inverts one half of the precedence rule in
    # `sysinit/pkg/ui/rollup.lua`. The suite must fail against both. If a
    # substitution stops matching, the mutant is identical to the original and
    # the guard below reports that rather than passing silently.
    mutate() {
      cp -r "$src" "$TMPDIR/mutant"
      chmod -R u+w "$TMPDIR/mutant"
      local f="$TMPDIR/mutant/sysinit/pkg/ui/rollup.lua"
      sed -i "s|$1|$2|" "$f"
      if cmp -s "$f" "$tree/sysinit/pkg/ui/rollup.lua"; then
        echo "FAIL: mutant '$3' changed nothing; the pattern no longer matches." >&2
        echo "Update checks/wezterm-rollup.nix to match the current reducer." >&2
        exit 1
      fi
      if lua "$suite" "$TMPDIR/mutant" > "$TMPDIR/mutant.out" 2>&1; then
        echo "FAIL: the suite passed against mutant '$3'." >&2
        echo "A test that passes against a broken reducer is not coverage." >&2
        cat "$TMPDIR/mutant.out" >&2
        exit 1
      fi
      rm -rf "$TMPDIR/mutant"
    }

    mutate 'rank > cur.rank' 'rank < cur.rank' 'inverted rank precedence'
    mutate 'a < b' 'a > b' 'inverted since tie-break'

    echo "OK: the suite fails against both precedence mutants" | tee "$out"
  ''
