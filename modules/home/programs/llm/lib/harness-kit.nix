{
  mkKit =
    {
      lib,
      pkgs,
      config,
    }:
    let

      llmLib = {
        instructions = import ./instructions.nix { inherit lib; };
      };
      skillsLib = import ../skills/render.nix { inherit pkgs; };
      mcpServers = import ./mcp-catalog.nix {
        inherit lib;
        routeServer = import ./mcp-routing.nix { inherit lib pkgs; };
        inherit (config.sysinit.llm.mcp)
          additionalServers
          suppressedServers
          harnessSuppressedServers
          harnessOverrides
          ;
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
