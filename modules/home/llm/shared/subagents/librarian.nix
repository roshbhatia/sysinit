{
  description = "Specialized codebase understanding agent for multi-repository analysis, searching remote codebases, retrieving official documentation, and finding implementation examples. MUST BE USED when users ask to look up code in remote repositories, explain library internals, or find usage examples in open source.";
  temperature = 0.1;

  useWhen = [
    "How do I use [library]?"
    "What's the best practice for [framework feature]?"
    "Why does [external dependency] behave this way?"
    "Find examples of [library] usage"
    "Working with unfamiliar npm/pip/cargo packages"
  ];

  avoidWhen = [
    "Implementation tasks (use direct tools)"
    "Code modification (use direct tools)"
    "Architecture decisions (use oracle)"
  ];

  tools = {
    bash = false;
    edit = false;
    glob = true;
    grep = true;
    list = true;
    lsp = false;
    patch = false;
    read = true;
    serena_find_file = true;
    serena_find_referencing_symbols = true;
    serena_find_symbol = true;
    serena_get_symbols_overview = true;
    serena_list_dir = true;
    serena_replace_content = false;
    serena_replace_symbol_body = false;
    serena_search_for_pattern = true;
    skill = false;
    webfetch = true;
    write = false;
  };
}
