# The committed cloud-agent files equal their render from
# `modules/shared/cloud.nix`, so a hand edit fails here rather than diverging
# from the facts. The second half proves the egress invariant on the rendered
# bytes: every https host the setup script contacts is in the Cursor allowlist.
{ pkgs, lib }:
let
  cloud = import ../flake/cloud-files.nix { inherit pkgs lib; };
  committed = {
    ".cursor/environment.json" = ../.cursor/environment.json;
    ".devin/blueprint.yaml" = ../.devin/blueprint.yaml;
    "hack/cloud-setup.sh" = ../hack/cloud-setup.sh;
  };
  compare = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: path: ''
      if ! cmp -s ${path} ${cloud.all}/${name}; then
        echo "DRIFT: ${name} differs from its render; run hack/generate-cloud.sh" >&2
        diff -u ${path} ${cloud.all}/${name} >&2 || true
        drift=1
      fi
    '') committed
  );
in
pkgs.runCommand "cloud-files" { nativeBuildInputs = [ pkgs.jq ]; } ''
  drift=0
  ${compare}
  [ "$drift" -eq 0 ]

  # Every host the script fetches from must be reachable from a Cursor box.
  grep -oE 'https://[A-Za-z0-9.-]+' ${cloud.setupScript} | sed 's|https://||' | sort -u > hosts
  jq -r '.egressAllowlist[]' ${cloud.environmentJson} | sort -u > allowed
  if missing="$(comm -23 hosts allowed)" && [ -n "$missing" ]; then
    echo "egress: hosts the setup script contacts but the allowlist omits:" >&2
    echo "$missing" >&2
    exit 1
  fi
  # A regression guard on the grep itself: the installer URL must be found.
  grep -qx '${cloud.facts.hostOf cloud.facts.installer.url}' hosts
  touch $out
''
