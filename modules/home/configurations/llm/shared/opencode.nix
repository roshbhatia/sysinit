{
  values,
}:

let
  defaultSkills = {
    verification-before-completion = {
      name = "verification-before-completion";
      description = "Use when about to claim work is complete, fixed, or passing—requires running verification commands and confirming output before making any success claims. Evidence before assertions always.";
    };
    receiving-code-review = {
      name = "receiving-code-review";
      description = "Use when receiving code review feedback, before implementing suggestions—verify against codebase reality and evaluate technical soundness before implementing.";
    };
    executing-plans = {
      name = "executing-plans";
      description = "Use when you have a written implementation plan to execute in a separate session with review checkpoints.";
    };
    systematic-debugging = {
      name = "systematic-debugging";
      description = "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes.";
    };
    using-git-worktrees = {
      name = "using-git-worktrees";
      description = "Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification.";
    };
    test-driven-development = {
      name = "test-driven-development";
      description = "Use when implementing any feature or bugfix, before writing implementation code.";
    };
    brainstorming = {
      name = "brainstorming";
      description = "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.";
    };
    using-superpowers = {
      name = "using-superpowers";
      description = "Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions.";
    };
  };

  defaultAgents = {
    librarian = {
      description = "Specialized codebase understanding agent for multi-repository analysis, searching remote codebases, retrieving official documentation, and finding implementation examples.";
      mode = "subagent";
      model = "anthropic/claude-sonnet-4-5";
      temperature = 0.1;
      tools = {
        write = false;
        edit = false;
        background_task = false;
      };
    };
    oracle = {
      description = "Expert technical advisor with deep reasoning for architecture decisions, code analysis, and engineering guidance.";
      mode = "subagent";
      model = "openai/gpt-5.2";
      temperature = 0.1;
      tools = {
        write = false;
        edit = false;
        bash = false;
        background_task = false;
      };
    };
  };

  additionalSkills = values.llm.opencode.skills or { };
  additionalAgents = values.llm.opencode.agents or { };
  allSkills = defaultSkills // additionalSkills;
  allAgents = defaultAgents // additionalAgents;
in
{
  skills = allSkills;
  agents = allAgents;
}
