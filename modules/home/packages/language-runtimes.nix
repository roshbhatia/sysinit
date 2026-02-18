{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language runtimes installed system-wide
    # Projects can override via shell.nix/flake.nix for specific versions

    bun
    go
    nodejs_22
    python311

    # Lua runtime & libraries (for neovim, wezterm, hammerspoon configs)
    hererocks
    luajit
    lua54Packages.cjson

    # Rust toolchain management via rustup
    cargo-watch

    # JavaScript/TypeScript tools
    typescript
    yarn

    # Go development tools
    delve
    ginkgo
    go-enum
    gofumpt
    gojsonstruct
    gomvp
    gotools # includes goimports
    gotestsum
    govulncheck
    json-to-struct
    mockgen
    reftools # includes fillstruct, fillswitch, fixplurals
    richgo

    # LSP servers
    awk-language-server
    bash-language-server
    cuelsp
    docker-compose-language-service
    docker-language-server
    gopls
    helm-ls
    jq-lsp
    lsp-ai
    lua-language-server
    nil
    nixd
    pyright
    simple-completion-language-server
    taplo
    typescript-language-server
    vale-ls
    vscode-langservers-extracted
    yaml-language-server

    # Formatters & Linters
    eslint
    golangci-lint
    nixfmt
    shellcheck
    shfmt
    stylua
    yamllint
  ];
}
