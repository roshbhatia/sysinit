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
    read = true;
    grep = true;
    glob = true;
    list = true;
    webfetch = true;
    write = false;
    edit = false;
    patch = false;
    bash = false;
    lsp = false;
    skill = false;
  };
}
