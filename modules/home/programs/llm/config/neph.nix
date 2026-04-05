# modules/home/programs/llm/config/neph.nix
# Imports neph.nvim's home-manager module to declaratively manage
# lifecycle hook configs for AI coding agents (Claude, Gemini, Cursor, etc.).
# Review gate hooks are still managed per-project via `neph integration toggle`.
{ inputs, ... }:
{
  imports = [ inputs.neph-nvim.homeManagerModules.default ];

  programs.neph = {
    enable = true;
    # All integrations default to true; disable selectively if needed:
    # integrations.codex = false;
  };
}
