# Every harness this repo configures, one module each.
#
# A harness that owns assets is a directory holding its `default.nix` beside
# them, so the path names the owner: an asset under `pi/` is pi's. A harness with
# no asset stays a single file. Nothing else belongs here. The cross-harness
# modules (`../acp.nix`, `../mcp-servers.nix`) sit at the module root, because a
# directory whose rule is "one module per harness" stops being a rule the moment
# it holds something that is not one.
#
# `llm/default.nix` cross-checks this list against
# `lib/instructions.nix`'s `harnessCoverage`, so a harness added here without a
# declared context path fails evaluation rather than shipping with no context.
{
  imports = [
    ./amp.nix
    ./claude
    ./codex.nix
    ./copilot-cli.nix
    ./crush.nix
    ./cursor
    ./devin.nix
    ./gemini
    ./goose.nix
    ./opencode
    ./pi
  ];
}
