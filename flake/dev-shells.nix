{ pkgs }:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  default = pkgs.mkShellNoCC {
    name = "sysinit-dev";
    packages = [
      pkgs.nh
      pkgs.nixfmt
      pkgs.treefmt
      pkgs.ruff
      pkgs.python3
      pkgs.uv
      pkgs.nufmt
      pkgs.actionlint
      pkgs.clang
      pkgs.clang-tools
      pkgs.go
      pkgs.taskwarrior-cli
      pkgs.golangci-lint
      pkgs.shfmt
      pkgs.shellcheck
      pkgs.zsh
      pkgs.nushell
      pkgs.nushellPlugins.formats
      pkgs.fish
      pkgs.carapace
      pkgs.lua5_4
      pkgs.lua-language-server
      pkgs.jq
      pkgs.libxml2
      pkgs.fd
      pkgs.ripgrep
      pkgs.ast-grep
      pkgs.statix
      pkgs.deadnix
      pkgs.stylua
      pkgs.cue
      pkgs.taplo
      pkgs.typescript
      pkgs.nodejs_24
      pkgs.prefetch-npm-deps
      pkgs.eslint
      pkgs.prettier
      pkgs.yamllint
      pkgs.vale
    ];
  };
}
// lib.optionalAttrs (system != "aarch64-linux") {
  release = pkgs.mkShellNoCC {
    name = "sysinit-release";
    SEMANTIC_RELEASE_ROOT = "${pkgs.semantic-release}/lib/node_modules/semantic-release";
    packages = [
      pkgs.git
      pkgs.nodejs
      pkgs.semantic-release
    ];
  };
}
