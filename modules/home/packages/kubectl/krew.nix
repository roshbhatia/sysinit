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
    fi
  '';
in
{
  programs.zsh.initContent = lib.mkAfter krewInitScript;
}
