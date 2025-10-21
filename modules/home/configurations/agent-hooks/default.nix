{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentHooksPath = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/agent-hooks";
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  # Create symlinks for hook scripts in ~/.local/bin
  home.file = {
    # Generic hook entry points (shared by all agents)
    ".local/bin/agent-hook-before-read" = {
      source = mkOutOfStoreSymlink "${agentHooksPath}/hooks/before_read_file.py";
      executable = true;
    };
    ".local/bin/agent-hook-after-write" = {
      source = mkOutOfStoreSymlink "${agentHooksPath}/hooks/after_write_file.py";
      executable = true;
    };
    ".local/bin/agent-hook-before-shell" = {
      source = mkOutOfStoreSymlink "${agentHooksPath}/hooks/before_shell_exec.py";
      executable = true;
    };
    ".local/bin/agent-hook-before-mcp" = {
      source = mkOutOfStoreSymlink "${agentHooksPath}/hooks/before_mcp_exec.py";
      executable = true;
    };

    # Symlink the entire lib directory for imports
    ".local/lib/python/agent_hooks" = {
      source = mkOutOfStoreSymlink "${agentHooksPath}/lib";
      recursive = true;
    };

    # Symlink the agents directory for adapters
    ".local/lib/python/agent_hooks_adapters" = {
      source = mkOutOfStoreSymlink "${agentHooksPath}/agents";
      recursive = true;
    };
  };

  # Environment variables for hook configuration
  home.sessionVariables = {
    # Master switch
    SYSINIT_AGENT_HOOKS_ENABLED = "true";

    # Debug mode (set to "true" to enable verbose logging)
    # SYSINIT_AGENT_HOOKS_DEBUG = "false";

    # Agent-specific toggles (all enabled by default)
    SYSINIT_AGENT_HOOKS_CURSOR_ENABLED = "true";
    SYSINIT_AGENT_HOOKS_CLAUDE_ENABLED = "true";
    SYSINIT_AGENT_HOOKS_OPENCODE_ENABLED = "true";

    # Feature flags
    SYSINIT_AGENT_HOOKS_DIFF_MODE = "true";
    SYSINIT_AGENT_HOOKS_AUTO_RELOAD = "true";
    SYSINIT_AGENT_HOOKS_PRE_OPEN_FILES = "true";

    # Performance settings
    SYSINIT_AGENT_HOOKS_ASYNC_WRITES = "true";
    SYSINIT_AGENT_HOOKS_TIMEOUT_MS = "200";

    # Add Python library path for hook imports
    PYTHONPATH = "$HOME/.local/lib/python:${"\${PYTHONPATH:-}"}";
  };

  # Ensure required packages are available
  home.packages = with pkgs; [
    # UV is required for running the hook scripts with inline dependencies
    uv
    # Python 3.11+ is required
    python311
  ];
}
