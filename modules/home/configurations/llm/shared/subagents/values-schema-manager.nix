{
  description = "Specialized agent for managing type-safe configuration schemas in modules/shared/lib/schema.nix. Handles schema design, type definitions, validation rules, and documentation generation for user-facing configuration options.";
  temperature = 0.1;

  useWhen = [
    "Adding new values.nix configuration options"
    "Defining types in modules/shared/lib/schema.nix"
    "Writing validation rules or assertions"
    "Schema migration or refactoring"
    "Documentation generation (task docs:values)"
    "Type errors in configuration values"
    "Designing structured configuration options"
  ];

  avoidWhen = [
    "Implementing feature logic (use direct tools)"
    "Nix builds (use nix-flake-operator)"
    "Lua configuration (use lua-config-specialist)"
    "Simple value changes (use direct tools)"
    "Format-only changes (use build-validator)"
  ];

  tools = {
    bash = true;
    edit = true;
    glob = true;
    grep = true;
    list = true;
    lsp = false;
    patch = true;
    read = true;
    serena_find_file = true;
    serena_find_referencing_symbols = true;
    serena_find_symbol = true;
    serena_get_symbols_overview = true;
    serena_list_dir = true;
    serena_replace_content = true;
    serena_replace_symbol_body = true;
    serena_search_for_pattern = true;
    skill = false;
    webfetch = false;
    write = true;
  };
}
