{
  description = "Expert in Lua configuration management across Neovim plugins, WezTerm, Hammerspoon, and Sketchybar. Handles plugin configuration, keybindings, LSP setup, and cross-tool Lua patterns. Specialized in the sysinit Lua module structure.";
  temperature = 0.2;

  useWhen = [
    "Configuring Neovim plugins (70+ plugins in lua/sysinit/plugins/)"
    "Setting up LSP, DAP, or completion configurations"
    "Writing or modifying WezTerm Lua config"
    "Hammerspoon automation scripts"
    "Sketchybar widget configuration"
    "Lua keybinding or autocmd setup"
    "Debugging Lua configuration errors"
    "Cross-tool Lua pattern consistency"
  ];

  avoidWhen = [
    "Nix build operations (use nix-flake-operator)"
    "Values schema changes (use values-schema-manager)"
    "Shell scripting (use direct tools)"
    "Documentation lookups (use librarian)"
    "Plugin selection decisions (use oracle)"
  ];

  tools = {
    bash = true;
    edit = true;
    glob = true;
    grep = true;
    list = true;
    lsp = true;
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
