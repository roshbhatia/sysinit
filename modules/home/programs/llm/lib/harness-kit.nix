# harness-kit: collapses the duplicated `let llmLib = ...; skillsLib = ...;
# mcpServers = ...; defaultInstructions = ...;` block that every harness
# config repeats into a single `mkKit { lib, pkgs, config }` call.
#
# Returns an attrset with exactly four keys:
#   llmLib       — the same shape as `import ../lib { inherit lib; }`
#   skillsLib    — the same shape as `import ../skills.nix { inherit pkgs; }`
#   mcpServers   — the same shape as `import ../mcp.nix { inherit lib; ... }`
#   mkInstructions { harness, skillsRoot }
#                — equivalent to llmLib.instructions.makeInstructions { ... }
#                  with localSkillDescriptions partial-applied.
#
# `harness` is required, not defaulted: it selects that harness's own word for a
# spawned helper agent (see lib/vocab.nix) and decides whether the Skills
# section renders at all, so a silent wrong default would ship the wrong text.
#
# Usage from a harness config:
#   let
#     llmLib = import ../lib { inherit lib; };
#     kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };
#     instructions = kit.mkInstructions {
#       harness = "claude";
#       skillsRoot = "~/.claude/skills";
#     };
#   in { ... }
{
  mkKit =
    {
      lib,
      pkgs,
      config,
    }:
    let
      llmLib = import ../lib { inherit lib; };
      skillsLib = import ../skills.nix { inherit pkgs; };
      mcpServers = import ../mcp.nix {
        inherit lib;
        inherit (config.sysinit.llm.mcp) additionalServers;
      };
    in
    {
      inherit llmLib skillsLib mcpServers;

      mkInstructions =
        { harness, skillsRoot }:
        llmLib.instructions.makeInstructions {
          inherit (skillsLib) localSkillDescriptions;
          inherit harness skillsRoot;
        };

      # Like mkInstructions but appends outputStyleRules at the recency
      # position. Use for harnesses that have no native output-style layer.
      mkInstructionsWithStyle =
        { harness, skillsRoot }:
        llmLib.instructions.makeInstructionsWithStyle {
          inherit (skillsLib) localSkillDescriptions;
          inherit harness skillsRoot;
        };
    };
}
