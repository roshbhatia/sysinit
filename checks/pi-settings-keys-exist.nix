# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
pkgs.runCommand "pi-settings-keys-exist-check"
  {
    nativeBuildInputs = [ pkgs.ripgrep ];
  }
  ''
    bin=${pkgs.pi-coding-agent}/pi/pi
    docs=${pkgs.pi-coding-agent}/pi/docs/settings.md
    fail=0

    # The doc is the ground truth, not the binary's byte stream. A bare
    # substring search over 76 MB matches for reasons unrelated to whether
    # a name is a settings property: `rg -a editor` matches
    # `editorPaddingX` and a dozen doc strings, so a typo like
    # `editor` for `externalEditor` passed while pi never read it. The
    # shipped doc enumerates every real setting in a table as `` `name` ``.
    [ -f "$docs" ] || {
      echo "FAIL: pi no longer ships docs/settings.md; this check needs a new ground truth" >&2
      exit 1
    }

    # Declared keys must be documented settings of the installed build.
    for k in ${lib.concatStringsSep " " (import ../modules/home/programs/llm/harnesses/pi/settings-keys.nix).declared}; do
      # Anchored to the table column, and dotted children count: the doc
      # lists `compaction`, `retry`, `warnings` and four others only as
      # `compaction.enabled` style leaves, so a bare-name search rejected
      # real settings and blocked the declarations this check exists to
      # permit.
      if ! rg -q "^\| \`$k(\\.[A-Za-z0-9_]+)*\`" "$docs"; then
        echo "FAIL: pi.nix declares '$k' but the installed pi build does not document it as a setting" >&2
        fail=1
      fi
    done

    # An ownerPreference key must still BE a setting. It is deliberately
    # undeclared so the owner's runtime choice survives, and
    # `assertPreferencesUndeclared` blocks declaring it. If pi renames or
    # drops one, that assertion goes on blocking a declaration on behalf
    # of a key that no longer exists, and nothing would say so.
    for k in ${lib.concatStringsSep " " (import ../modules/home/programs/llm/harnesses/pi/settings-keys.nix).ownerPreference}; do
      if ! rg -q "^\| \`$k(\\.[A-Za-z0-9_]+)*\`" "$docs"; then
        echo "FAIL: '$k' is held back as owner preference but the installed pi build no longer documents it; re-evaluate the handback" >&2
        fail=1
      fi
    done

    # Retired keys must stay absent from BOTH, so a future edit cannot
    # quietly reintroduce one. The binary grep is kept here on purpose:
    # for absence, a substring search is the conservative direction, since
    # an incidental match only makes this stricter.
    for k in ${lib.concatStringsSep " " (import ../modules/home/programs/llm/harnesses/pi/settings-keys.nix).retired}; do
      if rg -qF "\`$k\`" "$docs"; then
        echo "FAIL: '$k' is retired but the installed build now documents it; re-evaluate it" >&2
        fail=1
      fi
      if rg -qa "$k" "$bin"; then
        echo "FAIL: '$k' is retired but now exists in the pi build; re-evaluate it" >&2
        fail=1
      fi
    done

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: every declared and held-back pi key is documented, every retired key is absent" | tee "$out"
  ''
