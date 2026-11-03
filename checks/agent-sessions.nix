{ pkgs }:
let
  plugins = import (pkgs.sysinit-wezterm-source + "/plugins.nix") { inherit pkgs; };
  agents = pkgs.writeText "agent-detection-patterns.json" (
    builtins.toJSON (import ../modules/home/programs/llm/harnesses/deck-patterns.nix)
  );
  lua = pkgs.lua5_4.withPackages (ps: [ ps.dkjson ]);
in
pkgs.runCommand "agent-sessions-test"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.bash
      pkgs.jq
      pkgs.coreutils
    ];
  }
  ''
    python3 ${./agent-sessions.py} ${../modules/home/programs/llm/runtime/agent-sessions.sh} ${../modules/home/programs/llm/runtime/agent-sessions.jq}
    python3 ${./tmux-status.py} ${lua}/bin/lua ${../modules/home/programs/llm/runtime/tmux-status.lua} ${pkgs.sysinit-wezterm-lua} ${plugins.agent-deck} ${agents}
    touch "$out"
  ''
