{
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;

  formatSubagentAsMarkdown =
    {
      config,
    }:
    let
      tools = config.tools or { };
      content = config.instructions or config.description or "";
      formatTool = toolName: toString (tools.${toolName} or true);
    in
    ''
      ---
      description: ${config.description or ""}
      mode: subagent
      temperature: ${toString (config.temperature or 0.1)}
      tools:
        write: ${formatTool "write"}
        edit: ${formatTool "edit"}
        bash: ${formatTool "background_task"}
      ---

      ${content}
    '';
}
