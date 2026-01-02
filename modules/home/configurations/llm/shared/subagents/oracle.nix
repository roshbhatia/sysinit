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
    read = true;
    grep = true;
    glob = true;
    list = true;
    lsp = true;
    write = false;
    edit = false;
    patch = false;
    bash = false;
    webfetch = false;
    skill = false;
  };
}
