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
        inherit (config.sysinit.llm.mcp) additionalServers suppressedServers;
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

      mkInstructionsWithStyle =
        { harness, skillsRoot }:
        llmLib.instructions.makeInstructionsWithStyle {
          inherit (skillsLib) localSkillDescriptions;
          inherit (config.sysinit.llm.instructions) extraSections;
          inherit harness skillsRoot;
        };
    };
}
