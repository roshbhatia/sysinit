{
  pkgs,
  lib,
  ...
}:
# Cross-layer chord collision gate for WezTerm.
#
# `modules/darwin/keybindings.nix` already asserts across symbolic
# hotkeys, aerospork, and the reserved chords. WezTerm was the layer it
let
  chordsLib = import ../modules/darwin/lib/chords.nix { inherit lib; };

  reserved = builtins.attrNames chordsLib.reservedChords;

  enabledHotkeyChords = lib.mapAttrsToList (_: hk: chordsLib.chordOfHotkey hk.keys) (
    lib.filterAttrs (_: hk: hk.enable && (hk ? keys)) chordsLib.baseSymbolicHotkeys
  );

  # ui.lua binds these on top of keybindings.lua. They are declared
  # rather than extracted because ui.lua cannot load under the stub:
  # it pulls in tabline, lantern, and workspace-manager and fails at
  # line 1562. Keep in step by hand if ui.lua's bindings change.
  uiChords = [
    "cmd+shift+l"
    "cmd+s"
  ]
  ++ (map (n: "ctrl+shift+${toString n}") (lib.range 1 9));

  # Overlaps that are known and deliberately tolerated. Each needs a
  # reason; an empty reason is not an entry.
  #
  # cmd+m: symbolic hotkey ID 233 (enabled, cmd+m) versus WezTerm's
  acceptedOverlaps = [ "cmd+m" ];
in
pkgs.runCommand "wezterm-chord-collision-check"
  {
    nativeBuildInputs = [ pkgs.lua5_4 ];
    otherChords = lib.concatStringsSep "\n" (lib.unique (reserved ++ enabledHotkeyChords));
    uiChords = lib.concatStringsSep "\n" uiChords;
    accepted = lib.concatStringsSep "\n" acceptedOverlaps;
  }
  ''
    chordcheck=${../modules/home/programs/wezterm/chordcheck}
    lua_root=${../modules/home/programs/wezterm/lua}

    # utils.load_json_file errors on a missing file rather than
    # returning nil, and the loader reads $HOME/.config/wezterm at
    # module scope. The stub's json_parse ignores the contents, so an
    # empty object is enough to get past the read.
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME/.config/wezterm"
    echo '{}' > "$HOME/.config/wezterm/config.json"
    echo '{}' > "$HOME/.config/wezterm/env.json"

    lua "$chordcheck/extract.lua" "$chordcheck/stub.lua" "$lua_root" \
      > "$TMPDIR/from-lua" || {
      echo "FAIL: could not extract chords from keybindings.lua." >&2
      echo "The stub in chordcheck/ has drifted from what the module needs." >&2
      exit 1
    }

    printf '%s\n' "$uiChords" >> "$TMPDIR/from-lua"
    sort "$TMPDIR/from-lua" | sed '/^$/d' > "$TMPDIR/wezterm"
    printf '%s\n' "$otherChords" | sed '/^$/d' | sort -u > "$TMPDIR/other"
    printf '%s\n' "$accepted" | sed '/^$/d' | sort -u > "$TMPDIR/accepted"

    total=$(wc -l < "$TMPDIR/wezterm")
    if [ "$total" -lt 50 ]; then
      echo "FAIL: only $total wezterm chords extracted; expected the full set." >&2
      echo "Extraction silently under-reported rather than failing." >&2
      exit 1
    fi

    fail=0

    # 1. Duplicates inside WezTerm. `merge_keys` concatenates seven
    #    groups and WezTerm resolves a repeat silently, so one binding
    #    never fires and nothing says so.
    if dupes=$(uniq -d < "$TMPDIR/wezterm") && [ -n "$dupes" ]; then
      echo "FAIL: WezTerm binds the same chord twice:" >&2
      # shellcheck disable=SC2086  # deliberate word-splitting: one token per line
      printf '  %s\n' $dupes >&2
      fail=1
    fi

    # 2. Overlap with a layer that owns the chord globally.
    overlap=$(comm -12 <(sort -u "$TMPDIR/wezterm") "$TMPDIR/other")
    # shellcheck disable=SC2086  # deliberate word-splitting: one token per line
    unexpected=$(comm -23 <(printf '%s\n' $overlap | sed '/^$/d' | sort -u) "$TMPDIR/accepted")
    if [ -n "$unexpected" ]; then
      echo "FAIL: WezTerm claims a chord another layer owns:" >&2
      # shellcheck disable=SC2086  # deliberate word-splitting: one token per line
      printf '  %s\n' $unexpected >&2
      echo "Rebind it, or add it to acceptedOverlaps with a reason." >&2
      fail=1
    fi

    # 3. Aerospork invariant. See the header.
    if alt=$(grep '^alt+\|+alt+' "$TMPDIR/wezterm") && [ -n "$alt" ]; then
      echo "FAIL: WezTerm now binds ALT chords:" >&2
      # shellcheck disable=SC2086  # deliberate word-splitting: one token per line
      printf '  %s\n' $alt >&2
      echo "Aerospork owns ALT. Compare against modules/darwin/aerospork.nix" >&2
      echo "or drop the ALT binding." >&2
      fail=1
    fi

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: $total wezterm chords, no unaccepted collision" | tee "$out"
  ''
