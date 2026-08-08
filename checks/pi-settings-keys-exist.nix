{
  pkgs,
  lib,
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

    [ -f "$docs" ] || {
      echo "FAIL: pi no longer ships docs/settings.md; this check needs a new ground truth" >&2
      exit 1
    }

    for k in ${lib.concatStringsSep " " (import ../modules/home/programs/llm/harnesses/pi/settings-keys.nix).declared}; do
      if ! rg -q "^\| \`$k(\\.[A-Za-z0-9_]+)*\`" "$docs"; then
        echo "FAIL: pi.nix declares '$k' but the installed pi build does not document it as a setting" >&2
        fail=1
      fi
    done

    for k in ${lib.concatStringsSep " " (import ../modules/home/programs/llm/harnesses/pi/settings-keys.nix).ownerPreference}; do
      if ! rg -q "^\| \`$k(\\.[A-Za-z0-9_]+)*\`" "$docs"; then
        echo "FAIL: '$k' is held back as owner preference but the installed pi build no longer documents it; re-evaluate the handback" >&2
        fail=1
      fi
    done

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
