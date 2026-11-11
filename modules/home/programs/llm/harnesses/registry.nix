{
  amp = {
    shellAlias = {
      name = "amp";
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
    skillRoot = ".config/amp/skills";
    acp = true;
    openspecTool = [ ];
    guard = "globs";
    gate = "none";
    projectDir = ".agents/";
    transcriptRoot = null;
    exitHook = false;
    launch = {
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ ];
        env = { };
      };
    };
  };

  claude = {
    shellAlias = {
      name = "cld";
    };
    label = "Claude Code";
    module = ./claude;
    context = "~/.claude/CLAUDE.md";
    contextStyle = "~/.claude/output-styles/${(import ../lib/output-style.nix).name}.md";
    skillLoader = true;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = null;
    package = null;
    glyph = "";
    command = "claude";
    launch = {
      # Continues the most recent session in the working directory.
      continueArgs = [ "--continue" ];
      modelFlag = "--model";
      resumeArgs = [ "--resume" ];
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--dangerously-skip-permissions" ];
        env = { };
      };
    };
    skillRoot = ".claude/skills";
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
    };
    label = "Codex";
    module = ./codex.nix;
    context = "~/.codex/AGENTS.md";
    skillLoader = false;
    ownIcon = true;
    notify = "hook";
    editBus = true;
    bridge = null;
    package = null;
    glyph = "󱗿";
    command = "codex";
    launch = {
      # Continues the most recent session in the working directory.
      continueArgs = [
        "resume"
        "--last"
      ];
      modelFlag = "--model";
      resumeArgs = [ "resume" ];
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--dangerously-bypass-approvals-and-sandbox" ];
        env = { };
      };
    };
    skillRoot = ".claude/skills";
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
    skillRoot = ".copilot/skills";
    acp = true;
    openspecTool = [ "github-copilot" ];

    guard = "hook";
    gate = "exit-code";
    projectDir = ".copilot/";
    transcriptRoot = null;
    exitHook = false;
    launch = {
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--allow-all" ];
        env = { };
      };
    };
  };

  crush = {
    shellAlias = {
      name = "crs";
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
    skillRoot = ".claude/skills";
    acp = false;
    openspecTool = [ "crush" ];
    guard = "none";
    gate = "none";
    projectDir = ".crush/";
    transcriptRoot = null;
    exitHook = false;
    launch = {
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--yolo" ];
        env = { };
      };
    };
  };

  cursor = {
    shellAlias = {
      name = "cur";
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
    skillRoot = ".claude/skills";
    launch = {
      modelFlag = "--model";
      resumeArgs = [ "--resume" ];
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--yolo" ];
        env = { };
      };
    };
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
    skillRoot = ".config/devin/skills";
    acp = true;
    openspecTool = [ ];
    guard = "both";
    gate = "exit-code";
    projectDir = ".devin/";
    transcriptRoot = null;
    exitHook = false;
    launch = {
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [
          "--permission-mode"
          "dangerous"
        ];
        env = { };
      };
    };
  };

  fx = {
    shellAlias = {
      name = "fxx";
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
    skillRoot = ".claude/skills";
    acp = true;
    openspecTool = [ ];
    guard = "globs";
    gate = "none";
    projectDir = ".fx/";
    transcriptRoot = "~/.fx/sessions";
    exitHook = false;
    launch = {
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ ];
        env = {
          FX_PERMISSION_MODE = "full-access";
        };
      };
    };
  };

  gemini = {
    shellAlias = {
      name = "gmn";
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
    skillRoot = ".claude/skills";
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
    launch = {
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--dangerously-skip-permissions" ];
        env = { };
      };
    };
  };

  goose = {
    shellAlias = {
      name = "gse";
      args = [ "session" ];
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
    launch = {
      # Continues the most recent session in the working directory.
      continueArgs = [
        "session"
        "--resume"
      ];
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ ];
        env = {
          GOOSE_MODE = "auto";
        };
      };
    };
    skillRoot = ".claude/skills";
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
    launch = {
      # Continues the most recent session in the working directory.
      continueArgs = [ "--continue" ];
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--auto" ];
        env = { };
      };
    };
    skillRoot = ".claude/skills";
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
    launch = {
      # Continues the most recent session in the working directory.
      continueArgs = [ "--continue" ];
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [ "--approve" ];
        env = { };
      };
    };
    skillRoot = ".claude/skills";
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
    };
    label = "Strands";
    module = ./strands.nix;
    context = "~/.strands/cli/config.json";
    contextKey = [
      "profile"
      "instructions"
    ];
    skillLoader = true;
    ownIcon = false;
    notify = "scrape";
    editBus = false;
    bridge = null;
    package = "strands-cli";
    glyph = "S";
    command = "strands";
    skillRoot = ".claude/skills";
    launch = {
      modelFlag = "--model";
      # Runs without permission prompts; the shell aliases and session launchers use it.
      fullAccess = {
        args = [
          "--set"
          "interventions=null"
        ];
        env = { };
      };
    };
    acp = true;
    openspecTool = [ ];
    guard = "none";
    gate = "none";
    projectDir = ".agent/";
    transcriptRoot = null;
    exitHook = false;
  };
}
