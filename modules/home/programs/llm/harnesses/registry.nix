# One entry per harness.
{
  amp = {
    label = "Amp";
    module = ./amp.nix;
    context = "~/.config/amp/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "amp-cli";
    neovimAdapter = "amp";
    openspecTool = [ ];
  };

  atomic = {
    label = "Atomic";
    module = ./atomic;
    context = "~/.atomic/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "hook";
    # `tool_result` carries `details.resolvedPath`, an absolute path.
    editBus = true;
    bridge = ./atomic/extensions/sysinit-notify.ts;
    package = "atomic-coding-agent";
    neovimAdapter = "atomic";
    openspecTool = [ ];
  };

  claude = {
    label = "Claude Code";
    module = ./claude;
    context = "~/.claude/CLAUDE.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = null;
    # The `programs.claude-code` home-manager module installs it, not a `home.packages`
    # entry.
    package = null;
    neovimAdapter = "claudecode";
    openspecTool = [ "claude" ];
  };

  codex = {
    label = "Codex";
    module = ./codex.nix;
    context = "codex `context`";
    # Codex has no on-demand skill loader, so its instructions name every skill inline
    # instead of telling it where to look.
    skillLoader = false;
    ownIcon = true;
    notify = "hook";
    # `PostToolUse` names files only inside the apply-patch envelope.
    editBus = true;
    bridge = null;
    package = null;
    neovimAdapter = "codex";
    openspecTool = [ "codex" ];
  };

  copilot = {
    label = "Copilot";
    module = ./copilot-cli.nix;
    context = "~/.copilot/copilot-instructions.md";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "github-copilot-cli";
    neovimAdapter = "copilot";
    openspecTool = [ "github-copilot" ];
  };

  crush = {
    label = "Crush";
    module = ./crush.nix;
    context = "~/.config/crush/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "crush";
    neovimAdapter = "crush";
    openspecTool = [ "crush" ];
  };

  cursor = {
    label = "Cursor";
    module = ./cursor;
    context = "~/.cursor/rules/always.mdc";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "cursor-cli";
    neovimAdapter = "cursor";
    openspecTool = [ "cursor" ];
  };

  devin = {
    label = "Devin";
    module = ./devin.nix;
    context = "~/.config/devin/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "devin-cli";
    neovimAdapter = "devin";
    openspecTool = [ ];
  };

  gemini = {
    label = "Gemini";
    module = ./gemini;
    context = "~/.agents/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "antigravity-cli";
    neovimAdapter = "antigravity";
    openspecTool = [
      "antigravity"
      "gemini"
    ];
  };

  goose = {
    label = "Goose";
    module = ./goose.nix;
    context = "~/.config/goose/.goosehints";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "goose-cli";
    neovimAdapter = "goose";
    openspecTool = [ ];
  };

  hermes = {
    label = "Hermes";
    module = ./hermes.nix;
    # SOUL.md, not config.yaml: hermes injects it into the system prompt from
    # HERMES_HOME on every session, so it is the file that plays the part
    # `.goosehints` plays for goose.
    context = "~/.hermes/SOUL.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "hermes-agent";
    neovimAdapter = "hermes";
    openspecTool = [ ];
  };

  opencode = {
    label = "OpenCode";
    module = ./opencode;
    context = "~/.config/opencode/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    # `file.edited` carries one absolute path, for every editing tool.
    editBus = true;
    bridge = ./opencode/plugins/sysinit-notify.ts;
    package = "opencode";
    neovimAdapter = "opencode";
    openspecTool = [ "opencode" ];
  };

  prime-agent = {
    label = "Prime Agent";
    module = ./prime-agent;
    context = "~/.prime/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "hook";
    # not logged in on this machine, so `tool_result` is unverified.
    editBus = false;
    bridge = ./prime-agent/extensions/sysinit-notify.ts;
    package = "prime-agent";
    neovimAdapter = "primeagent";
    openspecTool = [ ];
  };

  pi = {
    label = "Pi";
    module = ./pi;
    context = "~/.pi/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    # `tool_result` carries `input.path`, relative to pi's cwd.
    editBus = true;
    bridge = ./pi/extensions/sysinit-notify.ts;
    package = "pi-coding-agent";
    neovimAdapter = "pi";
    openspecTool = [ "pi" ];
  };
}
