{ lib, pkgs }:
let
  instructions = import ../modules/home/programs/llm/lib/instructions.nix { inherit lib; };
  guards = import ../modules/home/programs/llm/lib/guards.nix { inherit lib; };
  orcHook = pkgs.writeText "orc-session-hook-test.sh" (
    guards.withOrcSession ''
      cat > payload
      printf '%s:%s' "$ORC_SESSION_ID" "$ORC_SCOPE" > invocation
    ''
  );
  failingOrcHook = pkgs.writeText "orc-session-hook-failure.sh" (guards.withOrcSession "exit 7");
  harnesses = builtins.attrNames (import ../modules/home/programs/llm/harnesses/registry.nix);
  render =
    renderer: harness:
    renderer {
      inherit harness;
      localSkillDescriptions = { };
    };
  base = map (render instructions.makeInstructions) harnesses;
  styled = map (render instructions.makeInstructionsWithStyle) harnesses;
  reportFragments = [
    "ORC_SESSION_ID"
    "ORC_SCOPE"
    "in the local environment once"
    "If either value is missing or empty, skip Orc discovery, session lookup,"
    "registration, and reporting"
    "Do not call Orc to determine whether this is"
    "Use Orc outside a session only when the user explicitly"
    "orc_current_session"
    "orc_session_report"
    "active Orc session"
    "`orchestrator`"
    "machine-readable Checkpoint"
    "`verification`"
    "`artifacts`"
    "`remaining_work`"
    "Transcript providers"
    "visible assistant prose"
    "Orc Output"
    "Orc Activity"
    "Do not copy either stream"
  ];
  hasOneReportInstruction =
    text:
    lib.all (fragment: lib.hasInfix fragment text) reportFragments
    && builtins.length (lib.splitString "orc_session_report" text) == 2;
in
assert lib.all hasOneReportInstruction base;
assert lib.all hasOneReportInstruction styled;
pkgs.runCommand "harness-instructions" { } ''
  unset ORC_SESSION_ID ORC_SCOPE
  bash ${orcHook}
  ORC_SESSION_ID=session bash ${orcHook}
  ORC_SCOPE=scope bash ${orcHook}
  ORC_SESSION_ID= ORC_SCOPE=scope bash ${orcHook}
  ORC_SESSION_ID=session ORC_SCOPE= bash ${orcHook}
  test ! -e invocation
  test ! -e payload

  printf '%s' '{"session_id":"harness-session"}' \
    | ORC_SESSION_ID=session ORC_SCOPE=scope bash ${orcHook}
  test "$(cat invocation)" = session:scope
  test "$(cat payload)" = '{"session_id":"harness-session"}'

  result=0
  ORC_SESSION_ID=session ORC_SCOPE=scope bash ${failingOrcHook} || result=$?
  test "$result" -eq 7
  touch "$out"
''
