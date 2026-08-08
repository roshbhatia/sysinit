{
  pkgs,
  lib,
  ...
}:
let
  chordsLib = import ../modules/darwin/lib/chords.nix { inherit lib; };

  reserved = builtins.attrNames chordsLib.reservedChords;

  enabledHotkeyChords = lib.mapAttrsToList (_: hk: chordsLib.chordOfHotkey hk.keys) (
    lib.filterAttrs (_: hk: hk.enable && (hk ? keys)) chordsLib.baseSymbolicHotkeys
  );

  acceptedOverlaps = [ "cmd+m" ];
in
pkgs.runCommand "agent-chord-collision-check"
  {
    nativeBuildInputs = [
      pkgs.lua5_4
      pkgs.findutils
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
    ];
    otherChords = lib.concatStringsSep "\n" (lib.unique (reserved ++ enabledHotkeyChords));
    accepted = lib.concatStringsSep "\n" acceptedOverlaps;
  }
  ''
    extract=${../modules/home/programs/wezterm/chordcheck/extract-static.lua}

    lua "$extract" wezterm ${../modules/home/programs/wezterm/lua}          > "$TMPDIR/wezterm.tsv"
    lua "$extract" neovim  ${../modules/home/programs/neovim/config/lua}    > "$TMPDIR/neovim.tsv"
    lua "$extract" pi      ${../modules/home/programs/llm/harnesses/pi}     > "$TMPDIR/pi.tsv"

    fail=0

    check_floor() {
      n=$(wc -l < "$2")
      if [ "$n" -lt "$3" ]; then
        echo "FAIL: only $n $1 chords extracted, expected at least $3." >&2
        echo "Extraction silently under-reported rather than failing." >&2
        fail=1
      fi
    }
    check_floor wezterm "$TMPDIR/wezterm.tsv" 10
    check_floor neovim  "$TMPDIR/neovim.tsv"  89
    check_floor pi      "$TMPDIR/pi.tsv"      3

    wez_cfg=${../modules/home/programs/wezterm/lua}
    if grep -rq "send_composed_key_when_left_alt_is_pressed *= *false" "$wez_cfg" 2>/dev/null; then
      echo "note: left-alt configured to send a chord; alt bindings permitted"
    else
      alt_binds=$(grep -hE '^alt\+|^[a-z+]*\balt\+' "$TMPDIR/neovim.tsv" "$TMPDIR/pi.tsv" 2>/dev/null \
        | grep -vE '^(cmd|ctrl)' || true)
      if [ -n "$alt_binds" ]; then
        echo "FAIL: alt binding on a composing modifier; it will type a character, not fire." >&2
        echo "Set send_composed_key_when_left_alt_is_pressed = false, or use another chord:" >&2
        printf '%s\n' "$alt_binds" | sed 's/^/  /' >&2
        fail=1
      fi
    fi

    for layer in wezterm pi; do
      dupes=$(cut -f1 "$TMPDIR/$layer.tsv" | sort | uniq -d || true)
      if [ -n "$dupes" ]; then
        echo "FAIL: $layer binds the same chord to more than one action:" >&2
        for d in $dupes; do
          echo "  $d" >&2
          grep -F "$d	" "$TMPDIR/$layer.tsv" | sed 's/^/    /' >&2
        done
        fail=1
      fi
    done

    printf '%s\n' "$otherChords" | sed '/^$/d' | sort -u > "$TMPDIR/other"
    printf '%s\n' "$accepted"    | sed '/^$/d' | sort -u > "$TMPDIR/accepted"
    cut -f1 "$TMPDIR/wezterm.tsv" "$TMPDIR/pi.tsv" | sort -u > "$TMPDIR/terminal"

    clash=$(comm -12 "$TMPDIR/terminal" "$TMPDIR/other" | comm -23 - "$TMPDIR/accepted" || true)
    if [ -n "$clash" ]; then
      echo "FAIL: chord claimed by both a terminal layer and the system layer:" >&2
      printf '%s\n' "$clash" | sed 's/^/  /' >&2
      fail=1
    fi

    [ "$fail" -eq 0 ] || exit 1
    printf 'OK: %s wezterm, %s neovim, %s pi chords; no collisions\n' \
      "$(wc -l < "$TMPDIR/wezterm.tsv")" \
      "$(wc -l < "$TMPDIR/neovim.tsv")" \
      "$(wc -l < "$TMPDIR/pi.tsv")" | tee "$out"
  ''
