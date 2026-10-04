{
  amp = {
    shellAlias = {
      name = "amp";
      value = "amp --settings-file ~/.config/amp/unrestricted.json";
    };
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
    gate = "none";
    projectDir = ".agents/";
    transcriptRoot = null;
    exitHook = false;
  };

  claude = {
    shellAlias = {
      name = "cld";
      value = "claude --dangerously-skip-permissions";
    };
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
    launch.resumeArgs = [ "--resume" ];
    acp = true;
    openspecTool = [ "claude" ];
    guard = "hook";
    gate = "claude-json";
    projectDir = ".claude/";
    transcriptRoot = "~/.claude/projects";
    exitHook = true;
  };

  codex = {
    shellAlias = {
      name = "cdx";
      value = "codex --dangerously-bypass-approvals-and-sandbox";
    };
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
    launch.resumeArgs = [ "resume" ];
    acp = true;
    openspecTool = [ "codex" ];
    guard = "hook";
    gate = "claude-json";
    projectDir = ".codex/";
    transcriptRoot = "~/.codex/sessions";
    exitHook = false;
  };

  copilot = {
    shellAlias = {
      name = "cpl";
      value = "copilot --allow-all-tools --allow-all-paths";
    };
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

    guard = "hook";
    gate = "exit-code";
    projectDir = ".copilot/";
    transcriptRoot = null;
    exitHook = false;
  };

  crush = {
    shellAlias = {
      name = "crs";
      value = "crush --yolo";
    };
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
    gate = "none";
    projectDir = ".crush/";
    transcriptRoot = null;
    exitHook = false;
  };

  cursor = {
    shellAlias = {
      name = "cur";
      value = "cursor-agent --yolo";
    };
    label = "Cursor";
    module = ./cursor;
    context = "~/.cursor/rules/always.mdc";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = null;
    package = "cursor-cli";
    glyph = "";
    command = "cursor-agent";
    launch.modelFlag = "--model";
    launch.resumeArgs = [ "--resume" ];
    acp = true;
    openspecTool = [ "cursor" ];
    guard = "both";
    gate = "cursor";
    projectDir = ".cursor/";
    transcriptRoot = "~/.cursor/projects";
    exitHook = true;
  };

  devin = {
    shellAlias = {
      name = "dvn";
      value = "devin --permission-mode dangerous";
    };
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
    gate = "exit-code";
    projectDir = ".devin/";
    transcriptRoot = null;
    exitHook = false;
  };

  fx = {
    shellAlias = {
      name = "fxx";
      value = "env FX_PERMISSION_MODE=full-access fx";
    };
    label = "fx";
    module = ./fx.nix;
    context = "~/.fx/AGENTS.md";

    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "sysinit-fx";
    glyph = "▲";
    command = "fx";
    acp = true;
    openspecTool = [ ];
    guard = "globs";
    gate = "none";
    projectDir = ".fx/";
    transcriptRoot = "~/.fx/sessions";
    exitHook = false;
  };

  gemini = {
    shellAlias = {
      name = "gmn";
      value = "agy --dangerously-skip-permissions";
    };
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
    gate = "exit-code";
    projectDir = ".gemini/";
    transcriptRoot = null;
    exitHook = false;
  };

  goose = {
    shellAlias = {
      name = "gse";
      value = "env GOOSE_MODE=auto goose session";
    };
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
    gate = "none";
    projectDir = ".goose/";
    transcriptRoot = null;
    exitHook = false;
  };

  opencode = {
    shellAlias = {
      name = "opc";
      value = "opencode --auto";
    };
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
    gate = "none";
    projectDir = ".opencode/";
    transcriptRoot = "~/.local/share/opencode";
    exitHook = false;
  };

  pi = {
    shellAlias = {
      name = "pii";
      value = "pi --approve";
    };
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
    gate = "none";
    projectDir = ".pi/";
    transcriptRoot = null;
    exitHook = true;
  };

  strands = {
    shellAlias = {
      name = "stn";
      value = "strands --set interventions=null";
    };
    label = "Strands";
    module = ./strands.nix;
    context = "~/.strands/cli/config.json profile.instructions";
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "strands-cli";
    glyph = "S";
    command = "strands";
    launch.modelFlag = "--model";
    acp = true;
    openspecTool = [ ];
    guard = "none";
    gate = "none";
    projectDir = ".agent/";
    transcriptRoot = null;
    exitHook = false;
  };
}
