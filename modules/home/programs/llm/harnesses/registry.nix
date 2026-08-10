# One entry per harness.
{
  amp = {
    label = "Amp";
    module = ./amp.nix;
    context = "~/.config/amp/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    bridge = null;
    package = "amp-cli";
    neovimAdapter = "amp";
  };

  claude = {
    label = "Claude Code";
    module = ./claude;
    context = "~/.claude/CLAUDE.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    bridge = null;
    # The `programs.claude-code` home-manager module installs it, not a `home.packages`
    # entry.
    package = null;
    neovimAdapter = "claudecode";
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
    bridge = null;
    package = null;
    neovimAdapter = "codex";
  };

  copilot = {
    label = "Copilot";
    module = ./copilot-cli.nix;
    context = "~/.copilot/copilot-instructions.md";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    bridge = null;
    package = "github-copilot-cli";
    neovimAdapter = "copilot";
  };

  crush = {
    label = "Crush";
    module = ./crush.nix;
    context = "~/.config/crush/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    bridge = null;
    package = "crush";
    neovimAdapter = "crush";
  };

  cursor = {
    label = "Cursor";
    module = ./cursor;
    context = "~/.cursor/rules/always.mdc";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    bridge = null;
    package = "cursor-cli";
    neovimAdapter = "cursor";
  };

  devin = {
    label = "Devin";
    module = ./devin.nix;
    context = "~/.config/devin/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    bridge = null;
    package = "devin-cli";
    neovimAdapter = "devin";
  };

  gemini = {
    label = "Gemini";
    module = ./gemini;
    context = "~/.agents/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    bridge = null;
    package = "antigravity-cli";
    neovimAdapter = "antigravity";
  };

  goose = {
    label = "Goose";
    module = ./goose.nix;
    context = "~/.config/goose/.goosehints";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    bridge = null;
    package = "goose-cli";
    neovimAdapter = "goose";
  };

  opencode = {
    label = "OpenCode";
    module = ./opencode;
    context = "~/.config/opencode/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    bridge = ./opencode/plugins/sysinit-notify.ts;
    package = "opencode";
    neovimAdapter = "opencode";
  };

  pi = {
    label = "Pi";
    module = ./pi;
    context = "~/.pi/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    bridge = ./pi/extensions/sysinit-notify.ts;
    package = "pi-coding-agent";
    neovimAdapter = "pi";
  };
}
