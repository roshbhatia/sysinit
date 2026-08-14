{
  pkgs,
  lib,
  profile ? "workstation",
  ...
}:
let
  profiles = import ../shared/profile-tiers.nix { inherit lib; };

  manifest = builtins.fromTOML (builtins.readFile ../../bootstrap/tools.toml);
  minimalPackages = map (entry: pkgs.${entry.nix}) manifest.tool;
in
{
  home.packages =
    with pkgs;
    profiles.forProfile profile {
      minimal = minimalPackages;

      dev = [
        nixd
        nil
        nixfmt
        statix
        deadnix
        cachix
        nix-output-monitor
        nix-tree
        nix-your-shell
        nix-prefetch
        nix-prefetch-docker
        nix-prefetch-git
        nix-prefetch-github
        nvfetcher

        bash-language-server
        shellcheck
        shfmt
        gum
        grc

        go
        gopls
        delve
        golangci-lint
        gofumpt
        gotestsum
        govulncheck
        ginkgo
        go-enum
        gomvp
        (lib.lowPrio gotools)
        mockgen
        reftools
        richgo

        python311
        uv
        pipx
        pyright

        rustup
        cargo-watch
        zig

        nodejs_22
        bun
        typescript
        yarn
        eslint
        typescript-language-server
        vscode-langservers-extracted

        luajit
        hererocks
        lua-language-server
        stylua
        lua54Packages.cjson

        argocd
        helm-ls
        k9s
        kind
        krew
        kube-linter
        kubecolor
        kubectl
        kubectx
        kubernetes-helm
        kubernetes-zeitgeist
        kustomize
        stern

        docker
        docker-compose
        docker-buildx
        docker-color-output
        docker-compose-language-service
        docker-language-server

        ansible
        ansible-lint
        awscli2
        crossplane-cli
        cue
        cuelsp
        opentofu
        tflint
        tfsec
        tofu-ls
        upbound

        claude-agent-acp
        codex-acp
        copilot-language-server
        lsp-ai
        openspec
        specutil

        cupcake-cli
        open-policy-agent
        regols
        tree-sitter

        ast-grep
        awk-language-server
        codespell
        contextive
        devbox
        devcontainer
        go-task
        jq-lsp
        localias
        markdown-oxide
        meld
        mermaid-ascii
        pplx
        pretty-mermaid
        proselint
        sad
        sheets
        simple-completion-language-server
        taplo
        alerter
        textlint
        yaml-language-server
        yamllint
      ]
      ++ map (name: pkgs.${name}) (
        lib.filter (name: name != null) (
          lib.mapAttrsToList (_name: h: h.package) (import ./programs/llm/harnesses/registry.nix)
        )
      );

      workstation = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ hyprpicker ];
    };
}
