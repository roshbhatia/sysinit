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

  write-commit-roshan = {
    description = "Writes git commit messages in Roshan's distilled style: conventional-commit shape, lowercase subject, no body, no period, semicolon-joined two-clause subjects when needed. Use when drafting a commit message for this user, or when the user says 'commit this' / 'propose a commit message' / 'write commit'.";
    content = import ./write-commit-roshan.nix;
  };

  write-pr-review-roshan = {
    description = "Writes PR review comments in Roshan's distilled style: 1-3 sentences, verdict-first, em-dash for elaboration, colon for diagnosis, no hedging. Use when commenting on a PR, leaving a code review, replying to a review thread, or when the user says 'reply on the PR' / 'leave a comment' / 'review this'.";
    content = import ./write-pr-review-roshan.nix;
  };

  write-pr-body-roshan = {
    description = "Writes GitHub PR descriptions in Roshan's distilled style: issue URL on top, `## Summary` with full causal bullets, `## Risks` or `## Test plan` depending on PR type, no template defaults. Use when drafting a `gh pr create` body, opening a PR, or when the user says 'PR body' / 'pull request description'.";
    content = import ./write-pr-body-roshan.nix;
  };

  write-issue-roshan = {
    description = "Writes GitHub issue bodies and titles in Roshan's distilled style: lowercase fragment titles, follows upstream issue templates verbatim when present, use-case-first for feature requests, deterministic reproductions for bugs. Use when opening a GitHub issue, drafting `gh issue create` body, or when the user says 'file an issue' / 'open a bug' / 'issue body'.";
    content = import ./write-issue-roshan.nix;
  };
}
