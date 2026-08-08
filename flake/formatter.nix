{ nixpkgs, systems }:
nixpkgs.lib.genAttrs systems (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
  in
  pkgs.writeShellApplication {
    name = "sysinit-fmt";
    runtimeInputs = [
      pkgs.fd
      pkgs.nixfmt
      pkgs.shfmt
    ];
    text = ''
      shfmt_flags=(-i 2 -ci -sr -s)

      if [ "''${1:-}" = "--check" ]; then
        drift=0
        if ! fd --extension nix --type file --exec-batch nixfmt --check; then
          drift=1
        fi
        unformatted="$(fd --extension sh --type file \
          --exec-batch shfmt "''${shfmt_flags[@]}" -l || true)"
        if [ -n "$unformatted" ]; then
          echo "shfmt drift:" >&2
          echo "$unformatted" >&2
          drift=1
        fi
        [ "$drift" -eq 0 ] && echo "OK: formatting is clean"
        exit "$drift"
      fi

      if [ "$#" -gt 0 ]; then
        for target in "$@"; do
          case "$target" in
            *.sh) shfmt "''${shfmt_flags[@]}" -w "$target" ;;
            *) nixfmt "$target" ;;
          esac
        done
        exit 0
      fi

      fd --extension nix --type file --exec-batch nixfmt
      fd --extension sh --type file --exec-batch shfmt "''${shfmt_flags[@]}" -w
    '';
  }
)
