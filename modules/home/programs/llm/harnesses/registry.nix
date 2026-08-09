# One entry per harness. Every hand-kept harness list in this tree derives from
# this file, so adding a harness is one entry rather than fifteen edits.
#
# The enumeration of what this replaces is
# `openspec/changes/make-sysinit-composable/harness-lists.md`.
#
# Two consumers stay hand-kept and are checked for agreement instead of
# generated: `neovim/config/lua/harness/registry.lua` and the detection table in
# `wezterm/lua/sysinit/pkg/ui.lua`. Both configs have to work on a box with no
# Nix, so generating them would make the thing they must not depend on a
# build-time input. `neovimAdapter` below is what the first is checked against.
#
# Fields:
#   label          the display name a notifier shows
#   module         this harness's own module, imported by ./default.nix
#   context        the confirmed global context path, or the reason it has none
#   skillLoader    false when the harness cannot load skills on demand, so its
#                  instructions carry the skill list inline
#   ownIcon        false means the generic dashed circle, chosen rather than
#                  missing. `runtime/icons/<name>.svg` must exist when true.
#   notify         "hook" when the harness calls a notifier itself, "scrape"
#                  when the terminal has to watch its output
#   bridge         the notify artifact this repository installs into the
#                  harness, or null when the harness's own producer is enough
#   package        the nixpkgs attribute providing its CLI, or null when it
#                  arrives another way
#   neovimAdapter  the adapter module name under harness/adapters/, which is not
#                  always the harness name
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
    # The `programs.claude-code` home-manager module installs it, not a
    # `home.packages` entry.
    package = null;
    neovimAdapter = "claudecode";
  };

  codex = {
    label = "Codex";
    module = ./codex.nix;
    context = "codex `context`";
    # Codex has no on-demand skill loader, so its instructions name every skill
    # inline instead of telling it where to look.
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
