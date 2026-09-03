{
  mkKit =
    {
      lib,
      pkgs,
      config,
    }:
    let
      # Not `import ../lib`: from inside lib/ that resolves to this file's own
      # directory, so default.nix and this file imported each other and only
      # laziness kept it working. instructions is all any caller reads through here.
      llmLib = {
        instructions = import ./instructions.nix { inherit lib; };
      };
      skillsLib = import ../skills/render.nix { inherit pkgs; };
      mcpServers = import ./mcp-catalog.nix {
        inherit lib;
        inherit (config.sysinit.llm.mcp) additionalServers suppressedServers harnessOverrides;
      };
    in
    {
      inherit llmLib skillsLib mcpServers;

      mkInstructions =
        {
          harness,
          skillsRoot,
          extraSections ? [ ],
        }:
        llmLib.instructions.makeInstructions {
          inherit (skillsLib) localSkillDescriptions;
          extraSections = config.sysinit.llm.instructions.extraSections ++ extraSections;
          inherit harness skillsRoot;
        };

      mkInstructionsWithStyle =
        {
          harness,
          skillsRoot,
          extraSections ? [ ],
        }:
        llmLib.instructions.makeInstructionsWithStyle {
          inherit (skillsLib) localSkillDescriptions;
          extraSections = config.sysinit.llm.instructions.extraSections ++ extraSections;
          inherit harness skillsRoot;
        };
    };
}
