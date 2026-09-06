{ pkgs, ... }:

let
  racingNixEnv = pkgs.writeShellScript "racing-nix-env" ''
    set -euo pipefail

    test "$1" = --profile
    profile=$2
    test "$3" = --delete-generations
    shift 3

    profiles=$(dirname "$profile")
    ln -s "$RACE_NEW_TARGET" "$profiles/system-4-link"
    ln -sfn system-4-link "$profile"

    for generation in "$@"; do
      rm "$profiles/system-$generation-link"
    done
  '';
in
pkgs.runCommand "system-generation-prune"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.nix
    ];
  }
  ''
    test_root="$TMPDIR/system-generation-prune"
    profiles="$test_root/nix/var/nix/profiles"
    current="$test_root/run/current-system"
    mkdir -p "$profiles" "$(dirname "$current")"

    nix-env --profile "$profiles/system" --set ${pkgs.hello}
    nix-env --profile "$profiles/system" --set ${pkgs.jq}
    nix-env --profile "$profiles/system" --set ${pkgs.coreutils}
    ln -s "$(readlink "$profiles/system-3-link")" "$current"

    bash ${../modules/darwin/prune-system-generations.sh} \
      "$profiles/system" \
      "$current" \
      "$(command -v nix-env)" \
      "$(command -v readlink)" \
      "$(command -v sleep)" \
      1 \
      0

    test "$(readlink "$profiles/system")" = system-3-link
    test "$(readlink "$profiles/system-3-link")" = "$(readlink "$current")"
    test ! -e "$profiles/system-1-link"
    test ! -e "$profiles/system-2-link"

    nix-env --profile "$profiles/system" --set ${pkgs.hello}
    previous_target=$(readlink "$profiles/system-3-link")
    rm "$current"
    ln -s "$previous_target" "$current"

    bash ${../modules/darwin/prune-system-generations.sh} \
      "$profiles/system" \
      "$current" \
      "$(command -v nix-env)" \
      "$(command -v readlink)" \
      "$(command -v sleep)" \
      1 \
      0

    test -L "$profiles/system-3-link"
    test -L "$profiles/system-4-link"
    test "$(readlink "$profiles/system")" = system-4-link

    race_root="$TMPDIR/system-generation-race"
    race_profiles="$race_root/nix/var/nix/profiles"
    race_current="$race_root/run/current-system"
    mkdir -p "$race_profiles" "$(dirname "$race_current")"
    ln -s ${pkgs.hello} "$race_profiles/system-1-link"
    ln -s ${pkgs.jq} "$race_profiles/system-2-link"
    ln -s ${pkgs.coreutils} "$race_profiles/system-3-link"
    ln -s system-3-link "$race_profiles/system"
    ln -s ${pkgs.coreutils} "$race_current"

    RACE_NEW_TARGET=${pkgs.bash} \
      bash ${../modules/darwin/prune-system-generations.sh} \
      "$race_profiles/system" \
      "$race_current" \
      ${racingNixEnv} \
      "$(command -v readlink)" \
      "$(command -v sleep)" \
      1 \
      0

    test "$(readlink "$race_profiles/system")" = system-4-link
    test -L "$race_profiles/system-3-link"
    test "$(readlink "$race_profiles/system-3-link")" = "$(readlink "$race_current")"
    test ! -e "$race_profiles/system-1-link"
    test ! -e "$race_profiles/system-2-link"

    touch "$out"
  ''
