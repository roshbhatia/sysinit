{
  beads-workflow = {
    description = "task tracking, issue management, multi-step work with bd";
    content = import ./beads-workflow.nix;
  };
  lua-development = {
    description = "Lua for Neovim, WezTerm, Hammerspoon, Sketchybar";
    content = import ./lua-development.nix;
  };
  nix-development = {
    description = "Nix modules, flake structure, nixfmt, build/test";
    content = import ./nix-development.nix;
  };
  prd-workflow = {
    description = "new features: PRD creation, approval, implementation";
    content = import ./prd-workflow.nix;
  };
  session-completion = {
    description = "ending sessions: commit, push, hand off context";
    content = import ./session-completion.nix;
  };
  shell-scripting = {
    description = "shell scripts in hack/, Taskfile, shfmt";
    content = import ./shell-scripting.nix;
  };
}
