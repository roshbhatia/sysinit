_:
let
  promptFiles = [
    "ai-engineer"
    "backend-architect"
    "frontend-developer"
    "typescript-expert"
    "platform-engineer"
    "agent-organizer"
    "api-documenter"
    "context-manager"
  ];

  importPrompts = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = import ../prompts/${name}.nix;
    }) promptFiles
  );

  promptsToAgents =
    prompts:
    builtins.mapAttrs (_name: prompt: {
      inherit (prompt) description;
      inherit (prompt) mode;
      inherit (prompt) prompt;
    }) prompts;
in
{
  all = importPrompts;

  toAgents = promptsToAgents importPrompts;

  get = name: importPrompts.${name} or null;
}
