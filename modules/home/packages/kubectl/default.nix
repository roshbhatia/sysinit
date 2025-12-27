{
  lib,
  values,
  ...
}:

let
  krewPackages = [
    "ctx"
  ]
  ++ (values.krew.additionalPackages or [ ]);

  krewInitScript = ''
    if command -v kubectl &>/dev/null && command -v krew &>/dev/null; then
      for _krew_pkg in ${lib.concatStringsSep " " krewPackages}; do
        if ! kubectl krew list 2>/dev/null | grep -q "^$_krew_pkg$"; then
          kubectl krew install "$_krew_pkg" 2>/dev/null || true
        fi
      done
      # Cleanup krew plugins not managed by nix
      comm -23 <(kubectl krew list 2>/dev/null | awk 'NR>1 {print $1}' | sort) <(echo "${lib.concatStringsSep "\n" krewPackages}" | sort) | while read pkg; do
        [ -n "$pkg" ] && kubectl krew uninstall "$pkg" 2>/dev/null || true
      done
    fi
  '';
in
{
  programs.zsh.initContent = lib.mkAfter krewInitScript;
}
