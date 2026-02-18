{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Go
    go
    delve
    ginkgo
    go-enum
    gofumpt
    gojsonstruct
    gomvp
    gotools # includes goimports
    gopls
    gotestsum
    govulncheck
    json-to-struct
    mockgen
    reftools # includes fillstruct, fillswitch, fixplurals
    richgo
    golangci-lint

    # JavaScript/TypeScript/Node
    bun
    nodejs_22
    typescript
    yarn
    eslint
    typescript-language-server

    # Python
    python311
    pyright

    # Lua (for neovim, wezterm, hammerspoon configs)
    hererocks
    luajit
    lua54Packages.cjson
    lua-language-server
    stylua

    # Rust
    cargo-watch

    # Nix
    nil
    nixd
    nixfmt
    statix
    deadnix

    # Shell/Bash
    bash-language-server
    shellcheck
    shfmt

    # Markup/Config languages
    taplo # TOML
    yaml-language-server
    yamllint

    # DevOps/Infrastructure languages
    cuelsp
    helm-ls

    # Docker
    docker-compose-language-service
    docker-language-server

    # General/Multi-language LSP servers
    awk-language-server
    jq-lsp
    lsp-ai
    simple-completion-language-server
    vale-ls
    vscode-langservers-extracted # HTML, CSS, JSON, ESLint
  ];
}
