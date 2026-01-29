{
  description = "Specialized agent for Nix flake operations, build workflows, dependency management, and multi-host configuration testing. Handles nix-darwin and NixOS builds, flake updates, and build-time debugging.";
  temperature = 0.1;

  useWhen = [
    "Building or testing system configurations (task nix:build, nh, darwin-rebuild)"
    "Updating flake inputs or managing flake.lock"
    "Debugging build failures or derivation issues"
    "Multi-host configuration changes (lv426, arrakis, work)"
    "Testing cross-platform compatibility (darwin vs linux)"
    "Working with Nix packages, overlays, or inputs"
    "Flake validation or nix evaluation errors"
  ];

  avoidWhen = [
    "Simple file reads (use direct tools)"
    "Writing Lua or shell code (use lua-config-specialist)"
    "Schema design (use values-schema-manager)"
    "Pre-commit formatting issues (use build-validator)"
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
