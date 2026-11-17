{ pkgs }:
pkgs.runCommand "agent-sessions-test"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.nushell
      pkgs.bash
      pkgs.jq
      pkgs.coreutils
    ];
  }
  ''
    nu --no-config-file ${./agent-sessions.nu} \
      ${../modules/home/programs/llm/runtime/agent-sessions.sh} \
      ${../modules/home/programs/llm/runtime/agent-sessions.jq} \
      ${../modules/home/programs/llm/runtime/agent-review.sh} ${./fixtures/agent-sessions-command.nu}
    touch "$out"
  ''
