{
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;
  formatSubagentAsMarkdown =
    {
      name,
      config,
      model ? "anthropic/claude-sonnet-4-20250514",
    }:
    let
      tools = config.tools or { };
      content = config.instructions or config.description or "";
      formatTool = toolName: builtins.toString (tools.${toolName} or true);
    in
    ''
      ---
      description: ${config.description or ""}
      mode: subagent
      model: ${model}
      temperature: ${builtins.toString (config.temperature or 0.1)}
      tools:
        write: ${formatTool "write"}
        edit: ${formatTool "edit"}
        bash: ${formatTool "background_task"}
      ---

      ${content}
    '';
}
