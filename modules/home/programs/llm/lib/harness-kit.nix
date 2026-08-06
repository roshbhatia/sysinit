# Collapses the `llmLib`/`skillsLib`/`mcpServers`/instructions block every
# harness config repeats into one `mkKit { lib, pkgs, config }` call.
#
# `harness` is required, not defaulted: it selects that harness's word for a
{
  mkKit =
    {
      lib,
      pkgs,
      config,
    }:
    let
      llmLib = import ../lib { inherit lib; };
      skillsLib = import ../skills/render.nix { inherit pkgs; };
      mcpServers = import ./mcp-catalog.nix {
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
          inherit (config.sysinit.llm.instructions) extraSections;
          inherit harness skillsRoot;
        };

      # Like mkInstructions but appends outputStyleRules at the recency
      # position. Use for harnesses that have no native output-style layer.
      mkInstructionsWithStyle =
        { harness, skillsRoot }:
        llmLib.instructions.makeInstructionsWithStyle {
          inherit (skillsLib) localSkillDescriptions;
          inherit (config.sysinit.llm.instructions) extraSections;
          inherit harness skillsRoot;
        };
    };
}
