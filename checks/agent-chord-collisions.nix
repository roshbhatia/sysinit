{
  pkgs,
  lib,
  ...
}:
# Cross-layer chord collision gate for every layer that binds a key.
#
# The predecessor covered symbolic hotkeys, aerospace, and WezTerm. pi and
# neovim sat outside it, and that absence had a measured cost: a sidebar toggle
# shipped on `alt+s`, which cannot fire on macOS because WezTerm defaults
# `send_composed_key_when_left_alt_is_pressed` to true and left-alt composes.
# Nothing failed. In the same pass `<leader>dt` was found bound twice in
# codediff.lua, to toggle_explorer and accept_incoming.
#
# Extraction is static (chordcheck/extract-static.lua) rather than by loading.
# The old check could not load ui.lua and compensated with a hand-written list of
# 11 chords against a file that declares more, kept in step by a comment asking
# someone to remember. Reading source text covers every layer with one mechanism
# and needs no stub per module. It cannot see a chord assembled from variables at
# runtime, so it is a floor on coverage.
let
  chordsLib = import ../modules/darwin/lib/chords.nix { inherit lib; };

  reserved = builtins.attrNames chordsLib.reservedChords;

  enabledHotkeyChords = lib.mapAttrsToList (_: hk: chordsLib.chordOfHotkey hk.keys) (
    lib.filterAttrs (_: hk: hk.enable && (hk ? keys)) chordsLib.baseSymbolicHotkeys
  );

  # Overlaps that are known and deliberately tolerated. Each needs a reason; an
  # empty reason is not an entry.
  #
  # cmd+m: symbolic hotkey ID 233 (enabled, cmd+m) versus WezTerm's own binding.
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

    # Extraction that silently under-reports is the failure mode this whole check
    # exists to prevent, so each layer declares a floor.
    #
    # Set just under the real counts (12 / 93 / 3), not comfortably under.
    # Mutation-tested: with the pi floor at 2, breaking the `registerShortcut`
    # pattern outright still passed, because the generic `"ctrl+..."` fallback
    # kept finding enough to clear it. A slack floor tests nothing. Lowering one
    # of these to accommodate a removal is a deliberate edit, which is the point.
    #
    # neovim went 93 -> 89 when a2a3f4a92 swapped fyler for neo-tree, and this
    # floor caught it. That is the mechanism working: a plugin swap that silently
    # drops four keymaps is exactly the change worth seeing.
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

    # 1. A modifier that composes rather than sending a chord.
    #
    # macOS turns left-alt into a compose key, and WezTerm's
    # `send_composed_key_when_left_alt_is_pressed` defaults to true. Until this
    # configuration sets that false, an alt+<key> binding types a character
    # instead of firing. Detected from config text, not assumed: if the option is
    # set false anywhere the rule lifts on its own.
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

    # 2. One mnemonic bound to two meanings. WezTerm resolves a repeat silently
    #    and neovim's last-wins is just as quiet, so one binding never fires and
    #    nothing says so.
    #
    #    NOT applied to neovim. A neovim mapping is keyed by chord AND mode AND
    #    buffer, and static extraction sees only the chord. Every candidate this
    #    rule produced was legitimate: gitsigns binds `<leader>ghs` in normal and
    #    visual mode, fyler and trouble both take `<C-t>` in their own buffers.
    #    Reporting those would bury a real find under noise and train the owner to
    #    ignore the gate, which is worse than not checking. neovim is still
    #    extracted, for the composing-modifier rule and the coverage floor.
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

    # 3. Collisions against the reserved and symbolic-hotkey layers, which win
    #    because they are handled before any terminal sees the key.
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
