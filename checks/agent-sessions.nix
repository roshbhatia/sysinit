{ pkgs }:
pkgs.runCommand "agent-sessions-test"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.python3
      pkgs.bash
      pkgs.jq
      pkgs.coreutils
    ];
  }
  ''
    python3 ${./agent-sessions.py} ${../modules/home/programs/llm/runtime/agent-sessions.sh} ${../modules/home/programs/llm/runtime/agent-sessions.jq} ${../modules/home/programs/llm/runtime/agent-review.sh}
    touch "$out"
  ''
