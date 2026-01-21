{
  description = "Specialized agent for pre-commit validation, formatting, and build-time checks. Handles task fmt workflows, statix/deadnix fixes, stylua formatting, shellcheck validation, and automated test workflows. Ensures all code meets project quality standards.";
  temperature = 0.1;

  useWhen = [
    "Pre-commit hook failures"
    "Running or fixing formatting (task fmt, task fmt:*:check)"
    "Addressing statix or deadnix warnings"
    "Stylua formatting issues"
    "Shellcheck or shfmt errors"
    "Build-time validation failures"
    "CI/CD-related fixes"
    "Documentation generation (task docs:values)"
  ];

  avoidWhen = [
    "Feature implementation (use direct tools)"
    "Complex Nix builds (use nix-flake-operator)"
    "Lua plugin configuration (use lua-config-specialist)"
    "Schema design (use values-schema-manager)"
    "Architecture decisions (use oracle)"
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
    serena_find_referencing_symbols = false;
    serena_find_symbol = false;
    serena_get_symbols_overview = false;
    serena_list_dir = true;
    serena_replace_content = true;
    serena_replace_symbol_body = false;
    serena_search_for_pattern = true;
    skill = false;
    webfetch = false;
    write = true;
  };
}
