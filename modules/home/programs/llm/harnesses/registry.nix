# Who the agents are, and what each one can do.
#
# guard says which destructive-command mechanism a harness has. "hook" is a
# regex the guard binary evaluates at PreToolUse, "globs" is a deny list the
# harness's own permission engine evaluates, "both" is both, and "none" means
# the harness exposes no deny mechanism this repo knows how to drive. null is
# rejected, so a new harness has to make the choice rather than inherit a gap.
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
    glyph = "󰫤";
    command = "amp";
    acp = true;
    openspecTool = [ ];
    guard = "globs";
    projectDir = ".agents/";
    transcriptRoot = null;
    exitHook = false;
  };

  atomic = {
    label = "Atomic";
    module = ./atomic;
    context = "~/.atomic/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "hook";
    editBus = true;
    bridge = ./atomic/extensions/sysinit-notify.ts;
    package = "atomic-coding-agent";
    glyph = "󰬛";
    command = "atomic";
    acp = false;
    openspecTool = [ ];
    guard = "globs";
    projectDir = ".atomic/";
    transcriptRoot = null;
    exitHook = true;
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
    package = null;
    glyph = "";
    command = "claude";
    launch.modelFlag = "--model";
    acp = true;
    openspecTool = [ "claude" ];
    guard = "hook";
    projectDir = ".claude/";
    transcriptRoot = "~/.claude/projects";
    exitHook = true;
  };

  codex = {
    label = "Codex";
    module = ./codex.nix;
    context = "codex `context`";
    skillLoader = false;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = null;
    package = null;
    glyph = "󱗿";
    command = "codex";
    launch.modelFlag = "--model";
    acp = true;
    openspecTool = [ "codex" ];
    guard = "hook";
    projectDir = ".codex/";
    transcriptRoot = "~/.codex/sessions";
    exitHook = false;
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
    glyph = "";
    command = "copilot";
    acp = true;
    openspecTool = [ "github-copilot" ];
    # "hook" by way of a JS shim: copilot has no declarative shell hook, so a
    # user-scoped extension calls the same guard binary the other hooks call.
    guard = "hook";
    projectDir = ".copilot/";
    transcriptRoot = null;
    exitHook = false;
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
    glyph = "";
    command = "crush";
    acp = false;
    openspecTool = [ "crush" ];
    guard = "none";
    projectDir = ".crush/";
    transcriptRoot = null;
    exitHook = false;
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
    glyph = "";
    command = "cursor-agent";
    acp = false;
    openspecTool = [ "cursor" ];
    guard = "globs";
    projectDir = ".cursor/";
    transcriptRoot = null;
    exitHook = false;
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
    glyph = "󰚩";
    command = "devin";
    acp = true;
    openspecTool = [ ];
    guard = "both";
    projectDir = ".devin/";
    transcriptRoot = null;
    exitHook = false;
  };

  fx = {
    label = "fx";
    module = ./fx.nix;
    context = "~/.fx/AGENTS.md";
    # fx scans ~/.claude/skills itself, so it needs no copy of the skill tree.
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "fx";
    glyph = "▲";
    command = "fx";
    acp = true;
    openspecTool = [ ];
    guard = "globs";
    projectDir = ".fx/";
    transcriptRoot = "~/.fx/sessions";
    exitHook = false;
  };

  gemini = {
    label = "Gemini";
    module = ./gemini;
    context = "~/.gemini/config/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "antigravity-cli";
    glyph = "󰊭";
    command = "agy";
    acp = false;
    openspecTool = [
      "antigravity"
      "gemini"
    ];
    guard = "hook";
    projectDir = ".gemini/";
    transcriptRoot = null;
    exitHook = false;
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
    glyph = "";
    command = "goose";
    acp = true;
    openspecTool = [ ];
    guard = "none";
    projectDir = ".goose/";
    transcriptRoot = null;
    exitHook = false;
  };

  hermes = {
    label = "Hermes";
    module = ./hermes.nix;
    context = "~/.hermes/SOUL.md";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "hermes-agent";
    glyph = "󱙺";
    command = "hermes";
    acp = true;
    openspecTool = [ ];
    guard = "none";
    projectDir = ".hermes/";
    transcriptRoot = null;
    exitHook = false;
  };

  opencode = {
    label = "OpenCode";
    module = ./opencode;
    context = "~/.config/opencode/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = ./opencode/plugins/sysinit-notify.ts;
    package = "opencode";
    glyph = "";
    command = "opencode";
    acp = true;
    openspecTool = [ "opencode" ];
    guard = "globs";
    projectDir = ".opencode/";
    transcriptRoot = "~/.local/share/opencode";
    exitHook = false;
  };

  prime-agent = {
    label = "Prime Agent";
    module = ./prime-agent;
    context = "~/.prime/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = false;
    notify = "hook";
    editBus = false;
    bridge = ./prime-agent/extensions/sysinit-notify.ts;
    package = "prime-agent";
    glyph = "󰙨";
    command = "prime-agent";
    acp = false;
    openspecTool = [ ];
    guard = "globs";
    projectDir = ".prime/";
    transcriptRoot = null;
    exitHook = true;
  };

  pi = {
    label = "Pi";
    module = ./pi;
    context = "~/.pi/agent/AGENTS.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = ./pi/extensions/sysinit-notify.ts;
    package = "pi-coding-agent";
    glyph = "󰏿";
    command = "pi";
    acp = true;
    openspecTool = [ "pi" ];
    guard = "globs";
    projectDir = ".pi/";
    transcriptRoot = null;
    exitHook = true;
  };
}
