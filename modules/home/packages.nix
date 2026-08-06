{ pkgs, lib, ... }:

{
  home.packages =
    with pkgs;
    [
      # Core Utilities
      coreutils
      curl
      wget
      findutils
      gettext
      gnugrep
      gnused
      gnumake
      pkg-config
      which
      tree
      unzip
      zip
      watch
      socat
      sshpass
      openssh
      gnupg
      bat
      eza
      fd
      ripgrep
      jq
      jqp
      yq-go
      # citelock (citation verification): lychee for link liveness, monolith for
      # single-file HTML capture. jq (above) feeds the Crossref REST query.
      lychee
      monolith
      duf
      htop
      glow
      # go-grip renders markdown as GitHub-styled HTML and serves it with live
      # reload. Replaces markdown-preview.nvim, whose `build` step ran a yarn
      # install inside the lazy plugin directory: a node toolchain and a network
      # fetch outside the generation, which is the one thing this repo does not
      # let any other dependency do.
      go-grip
      tokei
      scc
      chafa
      imagemagick
      _1password-cli

      # Git
      git
      gh
      delta
      git-crypt
      git-filter-repo
      libgit2

      # Nix
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

      # Bash
      bash-language-server
      shellcheck
      shfmt
      gum
      grc

      # Go
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

      # Python
      python311
      uv
      pipx
      pyright

      # Rust & Zig
      rustup
      cargo-watch
      zig

      # Node & Web
      nodejs_22
      bun
      typescript
      yarn
      eslint
      typescript-language-server
      vscode-langservers-extracted

      # Lua
      luajit
      hererocks
      lua-language-server
      stylua
      lua54Packages.cjson

      # Kubernetes
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

      # Docker
      docker
      docker-compose
      docker-buildx
      docker-color-output
      docker-compose-language-service
      docker-language-server

      # Infrastructure & IaC
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

      # AI & Editors
      amp-cli
      claude-agent-acp
      codex-acp
      copilot-language-server
      crush
      cursor-cli
      github-copilot-cli
      lsp-ai
      opencode
      openspec
      specutil

      # Policy & Governance
      cupcake-cli
      open-policy-agent
      regols
      pi-coding-agent
      tree-sitter

      # Config & Misc Dev
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
    ++ (lib.optionals pkgs.stdenv.hostPlatform.isLinux [ hyprpicker ]);
}
