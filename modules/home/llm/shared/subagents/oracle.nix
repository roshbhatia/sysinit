{
  description = "Expert technical advisor with deep reasoning for architecture decisions, code analysis, and engineering guidance.";
  temperature = 0.1;

  useWhen = [
    "Complex architecture design"
    "After completing significant work"
    "2+ failed fix attempts"
    "Unfamiliar code patterns"
    "Security/performance concerns"
    "Multi-system tradeoffs"
  ];

  avoidWhen = [
    "Simple file operations (use direct tools)"
    "First attempt at any fix (try yourself first)"
    "Questions answerable from code you've read"
    "Trivial decisions (variable names, formatting)"
    "Things you can infer from existing code patterns"
  ];

  tools = {
    bash = false;
    edit = false;
    glob = true;
    grep = true;
    list = true;
    lsp = true;
    patch = false;
    read = true;
    serena_find_file = false;
    serena_find_referencing_symbols = true;
    serena_find_symbol = true;
    serena_get_symbols_overview = true;
    serena_list_dir = false;
    serena_replace_content = false;
    serena_search_for_pattern = false;
    skill = false;
    webfetch = false;
    write = false;
  };
}
