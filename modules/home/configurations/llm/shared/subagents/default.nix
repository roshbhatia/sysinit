{
  librarian = import ./librarian.nix;
  oracle = import ./oracle.nix;

  formatSubagentAsMarkdown =
    {
      name,
      config,
    }:
    let
      inherit name;
      tools = config.tools or { };
      content = config.instructions or config.description or "";
      formatTool = toolName: toString (tools.${toolName} or true);
    in
    ''
      ---
      name: ${name}
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
