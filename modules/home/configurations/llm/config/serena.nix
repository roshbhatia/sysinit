{
  lib,
}:
let
  serenaExcludedTools = [
    "serena_jet_brains_find_referencing_symbols"
    "serena_jet_brains_find_symbol"
    "serena_jet_brains_get_symbols_overview"
    "serena_delete_memory"
    "serena_read_memory"
    "serena_write_memory"
    "serena_list_memories"
    "serena_edit_memory"
    "serena_insert_after_symbol"
    "serena_insert_at_line"
    "serena_insert_before_symbol"
    "serena_replace_lines"
    "serena_replace_content"
    "serena_replace_symbol_body"
    "serena_delete_lines"
    "serena_create_text_file"
    "serena_remove_project"
  ];

  serenaAllowedTools = [
    "serena_get_symbols_overview"
    "serena_find_symbol"
    "serena_find_referencing_symbols"
    "serena_find_file"
    "serena_search_for_pattern"
    "serena_list_dir"
  ];

  serenaServer = {
    command = "uvx";
    args = [
      "--from"
      "git+https://github.com/oraios/serena"
      "serena"
      "start-mcp-server"
      "--enable-web-dashboard"
      "false"
      "--excluded-tools"
      (lib.strings.concatStringsSep "," serenaExcludedTools)
      "--context"
      "claude-code"
    ];
    description = "Serena IDE assistant with AGENTS.md integration for project-aware coding assistance";
  };

  serenaPermissions = serenaAllowedTools;
in
{
  server = serenaServer;
  inherit serenaExcludedTools serenaAllowedTools serenaPermissions;
}
