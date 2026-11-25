{
  pkgs,
  lib,
  config,
  profile ? "workstation",
  values ? { },
  ...
}:
let
  profiles = import ../shared/profile-tiers.nix { inherit lib; };
  harnesses = import ./programs/llm/harnesses/registry.nix;

  manifest = fromTOML (builtins.readFile ./tools.toml);
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
        actionlint
        checkmake
        commitlint
        gum

        go
        gopls
        delve
        golangci-lint
        gofumpt
        go-tools
        gomodifytags
        impl
        gomvp
        (lib.lowPrio gotools)

        python311
        uv
        pipx
        pyright
        ruff

        rustup
        zig

        nodejs_24
        bun
        typescript
        yarn
        eslint
        prettier
        typescript-language-server
        graphql-language-service-cli
        vscode-langservers-extracted

        luajit
        hererocks
        lua-language-server
        stylua
        lua54Packages.cjson

        argocd
        helm-ls
        istioctl
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

        docker
        docker-compose
        docker-buildx
        docker-compose-language-service
        docker-language-server

        ansible
        cue
        cuelsp
        opentofu
        tflint
        tfsec
        tofu-ls
        upbound

        acp-amp
        amp-acp
        changes
        git-ai
        claude-agent-acp
        codex-acp
        copilot-language-server
        lsp-ai
        traces

        cupcake-cli
        open-policy-agent
        regols
        tree-sitter

        ast-grep
        awk-language-server
        codespell
        contextive
        go-task
        jq-lsp
        localias
        markdown-oxide
        mermaid-ascii
        pretty-mermaid
        sad
        sheets
        leaf-reader
        simple-completion-language-server
        taplo
        textlint
        vale
        yaml-language-server
        yamllint
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ alerter ]
      ++ lib.optional (builtins.elem "workflow-run-conductor" config.sysinit.llm.enabledOptInSkills) conductor-cli
      ++ map (name: pkgs.${harnesses.${name}.package}) config.sysinit.llm.harnessPackages;

      workstation =
        lib.optionals pkgs.stdenv.hostPlatform.isLinux [ hyprpicker ]
        ++ lib.optional (
          pkgs.stdenv.hostPlatform.isDarwin && builtins.elem "goose" config.sysinit.llm.harnessPackages
        ) goose-desktop;
    }
    ++ map (name: pkgs.${name}) (values.packages or [ ]);
}
