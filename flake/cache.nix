{ pkgs }:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
  cacheAttrs = [
    "hunk"
    "calldiff"
    "ast-grep-mcp"
    "strands-cli"
    "localias"
    "agent-desktop"
    "screen-relay"
    "git-ai"
    "mermaid-ascii"
    "pretty-mermaid"
    "pi-coding-agent"
    "fzf-nushell"
    "contextive"
    "codex"
    "opencode"
    "claude-code"
    "gomvp"
    "sysinit-gh-dash"
    "kubernetes-zeitgeist"
    "hererocks"
    "sheets"
    "leaf-reader"
    "alerter"
    "sysinit-gotools"
    "task-board"
    "task-queue"
    "tq-terminal-wezterm"
    "seshy"
    "changes"
    "changes-providers"
    "changes-provider-git-notes"
    "changes-neovim-plugin"
    "traces"
    "ere"
    "traces-providers"
    "ask"
    "ask-providers"
    "gate-cli"
    "gate-providers"
    "tether"
    "citelock"
    "sysinit-utils"
    "nuvim"
    "ioskeleyMono"
    "wumpusMono"
    "bookerly"
    "mise-nix"
    "meat"
    "amp-cli"
    "amp-acp"
    "acp-amp"
    "conductor-cli"
    "git-ai-gate"
    "agent-notes"
    "seshy-picker"
    "tether-picker"
    "zoxide-picker"
  ];

  linuxCacheAttrs = [
    "sunshine"
    "sysinit-swayfx"
  ];
in
pkgs.symlinkJoin {
  name = "sysinit-cache-bundle-${system}";
  paths =
    map
      (
        name:
        pkgs.${name}
          or (throw "cacheAttrs names `${name}`, which the overlay set does not define on ${system}")
      )
      (
        cacheAttrs
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxCacheAttrs
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          "jankyborders"
          "goose-cli"
          "goose-desktop"
        ]
      );
}
