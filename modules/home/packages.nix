{ pkgs, lib, ... }:

{
  home.packages =
    with pkgs;
    [
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
      lychee
      monolith
      duf
      htop
      glow
      go-grip
      tokei
      scc
      chafa
      imagemagick
      _1password-cli

      git
      gh
      delta
      git-crypt
      git-filter-repo
      libgit2

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

      cupcake-cli
      open-policy-agent
      regols
      pi-coding-agent
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
