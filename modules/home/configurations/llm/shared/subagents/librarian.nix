{
  category = "exploration";
  cost = "CHEAP";
  promptAlias = "Librarian";
  keyTrigger = "External library/source mentioned → fire `librarian` background";
  triggers = [
    {
      domain = "Librarian";
      trigger = "Unfamiliar packages / libraries, struggles at weird behaviour (to find existing implementation of opensource)";
    }
  ];
  useWhen = [
    "How do I use [library]?"
    "What's the best practice for [framework feature]?"
    "Why does [external dependency] behave this way?"
    "Find examples of [library] usage"
    "Working with unfamiliar npm/pip/cargo packages"
  ];
  description = "Specialized codebase understanding agent for multi-repository analysis, searching remote codebases, retrieving official documentation, and finding implementation examples using GitHub CLI, Context7, and Web Search. MUST BE USED when users ask to look up code in remote repositories, explain library internals, or find usage examples in open source.";
  temperature = 0.1;
  tools = {
    write = false;
    edit = false;
    background_task = false;
  };
}
