# One entry per harness.
#
# `openspecTool` names this harness in `openspec init --tools`, which the seshy
# postCreate hook runs in every new session. A list, not a string, because
# `gemini` here is antigravity-cli, which reads both `~/.agents` and
# `~/.gemini/config`, so both of openspec's adapters land in a tree it reads.
#
# Empty means openspec 1.6.0 ships no adapter for that harness: amp, atomic,
# devin, goose, hermes, and prime-agent. Six of the fourteen, and the loss is
# smaller than it looks. openspec's adapters install the four opsx skills
# repo-locally, and every one of these six is pointed at `~/.claude/skills`,
# where the same skills are installed for the machine. What they lose is the
# repo-local `opsx-*` prompt or command entry, not the skills.
#
# `modules/home/programs/seshy/default.nix` checks each name against the enum
# `openspec init --help` prints.
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
    openspecTool = [ ];
  };

  atomic = {
    label = "Atomic";
    module = ./atomic;
    context = "~/.atomic/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "hook";
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
    bridge = ./pi/extensions/sysinit-notify.ts;
    package = "pi-coding-agent";
    neovimAdapter = "pi";
    openspecTool = [ "pi" ];
  };
}
