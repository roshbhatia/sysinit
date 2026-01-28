{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  # === Cargo ===
  cargoPackages = values.cargo.additionalPackages or [ ];

  # === GitHub CLI ===
  ghPackages = [
    "https://github.com/github/gh-copilot"
  ]
  ++ (values.gh.additionalPackages or [ ]);

  # === Go ===
  goPackages = [
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

  # === Kubectl/Krew ===
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

  # === Node (npm + yarn) ===
  npmPackages = [
    "@beads/bd"
  ]
  ++ (values.npm.additionalPackages or [ ]);

  yarnPackages = [
    "@anthropic-ai/claude-code"
    "@fission-ai/openspec@latest"
    "@github/copilot"
    "@sourcegraph/amp@latest"
    "opencode-ai@latest"
  ]
  ++ (values.yarn.additionalPackages or [ ]);

  # === Python (pipx + uvx) ===
  pipxPackages = values.pipx.additionalPackages or [ ];

  uvxPackages = [
    "hererocks"
    "https://github.com/github/spec-kit.git"
  ]
  ++ (values.uvx.additionalPackages or [ ]);

  # === Vet ===
  vetPackages = values.vet.additionalPackages or [ ];
in
{
  # === Cargo activation ===
  home.activation.cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "cargo" cargoPackages config
  );

  # === GitHub CLI activation ===
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "gh" ghPackages config
  );

  # === Go activation ===
  home.activation.goPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "go" goPackages config
  );

  # === Kubectl krew plugins ===
  programs.zsh.initContent = lib.mkAfter krewInitScript;

  # === npm configuration and activation ===
  home.file.".npmrc" = {
    text = ''
      prefix = ''${HOME}/.local/share/.npm-packages
      strict-ssl = false
    '';
  };

  home.activation.npmPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "npm" npmPackages config
  );

  # === Yarn activation ===
  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "yarn" yarnPackages config
  );

  # === pipx activation ===
  home.activation.pipxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "pipx" pipxPackages config
  );

  # === uv activation ===
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "uv" uvxPackages config
  );

  # === Vet activation ===
  home.activation.vetPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "vet" vetPackages config
  );
}
