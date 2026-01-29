{
  config,
  lib,
  values,
  utils,
  ...
}:

let

  packages = [
    "golang.org/x/tools/cmd/goimports@latest"
    "golang.org/x/tools/cmd/gonew@latest"
    "golang.org/x/vuln/cmd/govulncheck@latest"
    "gotest.tools/gotestsum@latest"
    "go.uber.org/mock/mockgen@latest"
    "github.com/abenz1267/gomvp@latest"
    "github.com/abice/go-enum@latest"
    "github.com/davidrjenni/reftools/cmd/fillswitch@latest"
    "github.com/davidrjenni/reftools/cmd/fillstruct@latest"
    "github.com/davidrjenni/reftools/cmd/fixplurals@latest"
    "github.com/kyoh86/richgo@latest"
    "github.com/onsi/ginkgo/v2/ginkgo@latest"
    "github.com/tmc/json-to-struct@latest"
    "github.com/twpayne/go-jsonstruct/v3/cmd/gojsonstruct@latest"
    "mvdan.cc/gofumpt@latest"
  ]
  ++ (values.go.additionalPackages or [ ]);

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
  home.activation.goPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "go" packages config
  );

  programs.zsh.initContent = lib.mkAfter krewInitScript;
}
