_:
{
  # Binary install + MCP integration plumbing only.
  # skills, agents, settings, hooks, and CLAUDE.md are managed by
  # sysinit.agents (modules/home/programs/sysinit-agents.nix).
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
}
