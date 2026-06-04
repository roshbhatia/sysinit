{ pkgs, lib }:

{
  shell-scripting = {
    description = "Use when writing or modifying shell scripts, particularly in the hack/ directory, Taskfile commands, or any bash automation in this repository.";
    content = import ./shell-scripting.nix;
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
    model = "haiku";
    effort = "low";
  };

  code-search = {
    description = "Routing guide for searching code: when to reach for builtin `rg`/`grep`/Glob (literal strings, known symbols, exact paths), `ast-grep`/`sg` (structural, AST-shaped patterns and refactor-grade matches), or `gh search` (repo-wide / org-wide / not-locally-cloned). Prefer ast-grep over plain grep for anything structural; prefer builtin grep for literal text.";
    content = import ./code-search.nix;
    allowed-tools = "Bash(rg:*) Bash(grep:*) Bash(ast-grep:*) Bash(sg:*) Bash(gh:*) Read Glob";
    model = "haiku";
    effort = "low";
  };

  opinionated-commit = {
    description = "Writes git commit messages in a terse, conventional-commit-shaped style. Lowercase preferred but not absolute, title-only by default, no body, no period. Supports the historical `<type>: <TICKET-ID>: <subject>` variant when a tracker ticket is in scope. Use when drafting a commit message or when the user says 'commit this' / 'propose a commit message' / 'write commit'.";
    content = import ./opinionated-commit.nix;
    model = "haiku";
    effort = "low";
  };

  opinionated-pr = {
    description = "Writes GitHub PR descriptions in a terse, opinionated style. Delegates body shape to the repo PR template when one exists; falls back to `## Summary` plus an optional ad-hoc validating-changes block. Never mutates an existing checklist. Use when drafting a `gh pr create` body, opening a PR, or when the user says 'PR body' / 'pull request description'.";
    content = import ./opinionated-pr.nix;
    model = "haiku";
    effort = "low";
  };

  opinionated-code-comments = {
    description = "Opinionated style for inline source-code comments. Default to no comment. Add a comment only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. No multi-paragraph docstrings. One short line max. Use when editing source files, when asked 'should I comment this', or whenever the agent considers adding a comment to code.";
    content = import ./opinionated-code-comments.nix;
    model = "haiku";
    effort = "low";
  };

  diagramming = {
    description = "Renders diagrams as ASCII via mermaid-ascii so they live inline in markdown — openspec proposals, design notes, exploration scratch, chat replies. Source-of-truth is Mermaid; the rendered ASCII gets pasted alongside. Use when a diagram clarifies more than prose: capability flow, state transitions, sequence-of-calls, option trees, dependency graphs, decision points, architecture sketches in /opsx artifacts or chat.";
    content = import ./diagramming.nix;
    allowed-tools = "Bash(mermaid-ascii:*) Read Write Edit";
  };
}
