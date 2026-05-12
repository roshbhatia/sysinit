# harness-kit: collapses the duplicated `let llmLib = ...; skillsLib = ...;
# mcpServers = ...; defaultInstructions = ...;` block that every harness
# config repeats into a single `mkKit { lib, pkgs, config }` call.
#
# Returns an attrset with exactly four keys:
#   llmLib       — the same shape as `import ../lib { inherit lib; }`
#   skillsLib    — the same shape as `import ../skills.nix { inherit pkgs; }`
#   mcpServers   — the same shape as `import ../mcp.nix { inherit lib; ... }`
#   mkInstructions skillsRoot
#                — equivalent to llmLib.instructions.makeInstructions { ... }
#                  with localSkillDescriptions and openspecVersion partial-
#                  applied so callers pass only skillsRoot.
#
# Usage from a harness config:
#   let
#     llmLib = import ../lib { inherit lib; };
#     kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };
#     instructions = kit.mkInstructions "~/.claude/skills";
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
        skillsRoot:
        llmLib.instructions.makeInstructions {
          inherit (skillsLib) localSkillDescriptions;
          openspecVersion = pkgs.openspec.version;
          inherit skillsRoot;
        };
    };
}
