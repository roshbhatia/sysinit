{ pkgs, lib }:

{
  shell-scripting = {
    description = "Use when writing or modifying shell scripts, particularly in the hack/ directory, Taskfile commands, or any bash automation in this repository.";
    content = import ./shell-scripting.nix;
  };

  openspec-propose = {
    description = "Drafts a new OpenSpec change with proposal, design, specs, and tasks in one pass. Use when the user mentions OpenSpec, says 'propose a change', wants to scope new work, asks to capture a plan before implementation, or invokes /opsx:propose.";
    content = import ./openspec-propose.nix;
    allowed-tools = "Bash(openspec:*) Read Write Edit";
  };

  openspec-apply = {
    description = "Implements the tasks defined in an existing OpenSpec change. Use when the user wants to start, continue, or resume implementation of a proposed change, work through tasks.md, or invokes /opsx:apply.";
    content = import ./openspec-apply.nix;
    allowed-tools = "Bash(openspec:*) Read Write Edit";
  };

  openspec-explore = {
    description = "Enters a thinking-partner mode for exploring ideas, investigating problems, and clarifying requirements before committing to a change. Use when the user wants to brainstorm, compare approaches, or reason about an unfamiliar problem space, or invokes /opsx:explore.";
    content = import ./openspec-explore.nix;
    allowed-tools = "Bash(openspec:*) Bash(rg:*) Bash(git:*) Read";
  };

  openspec-archive = {
    description = "Archives a completed OpenSpec change and merges its delta specs into the project's authoritative specs. Use when the user is finished implementing a change, says 'archive this', or invokes /opsx:archive.";
    content = import ./openspec-archive.nix;
    allowed-tools = "Bash(openspec:*) Read";
  };

  find-skills = {
    description = "Discovers and installs agent skills from the open skills ecosystem at skills.sh. Use when the user asks 'how do I do X', 'is there a skill for X', wants to extend agent capabilities, or wants to install something via npx skills.";
    content = import ./find-skills.nix { inherit pkgs lib; };
    allowed-tools = "Bash(npx:*) WebFetch";
  };

  seshy = {
    description = "Operates the seshy multi-repo tmux session manager via its non-interactive `sy` subcommands. Use when the user references a named session, asks to create or attach repos to a session, or wants to list, look up, or tear down a named multi-repo session. The interactive picker (`sy` with no arguments) is human-only.";
    content = import ./seshy.nix;
    allowed-tools = "Bash(sy:*) Bash(tmux:*)";
  };

  cocoindex-query = {
    description = "Primary semantic code-search mechanism. Wired into every harness as the `cocoindex` MCP server with local embeddings. Prefer it for intent / 'how is X done' queries; use `rg`/`grep` only for literal-string matches. Bootstraps a project index on first call via `refresh_index=True`; falls back to `rg` on any failure.";
    content = import ./cocoindex-query.nix;
    allowed-tools = "Bash(rg:*) Bash(grep:*) Read";
  };

  opinionated-commit = {
    description = "Writes git commit messages in a terse, conventional-commit-shaped style. Lowercase preferred but not absolute, title-only by default, no body, no period. Supports the historical `<type>: <TICKET-ID>: <subject>` variant when a tracker ticket is in scope. Use when drafting a commit message or when the user says 'commit this' / 'propose a commit message' / 'write commit'.";
    content = import ./opinionated-commit.nix;
  };

  opinionated-pr = {
    description = "Writes GitHub PR descriptions in a terse, opinionated style. Delegates body shape to the repo PR template when one exists; falls back to `## Summary` plus an optional ad-hoc validating-changes block. Never mutates an existing checklist. Use when drafting a `gh pr create` body, opening a PR, or when the user says 'PR body' / 'pull request description'.";
    content = import ./opinionated-pr.nix;
  };

  opinionated-code-comments = {
    description = "Opinionated style for inline source-code comments. Default to no comment. Add a comment only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. No multi-paragraph docstrings. One short line max. Use when editing source files, when asked 'should I comment this', or whenever the agent considers adding a comment to code.";
    content = import ./opinionated-code-comments.nix;
  };
}
