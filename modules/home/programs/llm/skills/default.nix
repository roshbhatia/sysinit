{ pkgs, lib }:

{
  shell-script-authoring = {
    description = "Use when writing or modifying shell scripts, particularly in the hack/ directory, Taskfile commands, or any bash automation in this repository.";
    content = import ./shell-script-authoring.nix;
  };

  skills-ecosystem-discovery = {
    description = "Discovers and installs agent skills from the open skills ecosystem at skills.sh. Use when the user asks 'how do I do X', 'is there a skill for X', wants to extend agent capabilities, or wants to install something via npx skills.";
    content = import ./skills-ecosystem-discovery.nix { inherit pkgs lib; };
    allowed-tools = "Bash(npx:*) WebFetch";
  };

  feature-based-session-manager = {
    description = "Operates the seshy multi-repo, feature-based session manager via its non-interactive `sy` subcommands. Use when the user references a named session, asks to create or attach repos to a session, or wants to list, look up, or tear down a named multi-repo session. The interactive picker (`sy` with no arguments) is human-only.";
    content = import ./feature-based-session-manager.nix;
    allowed-tools = "Bash(sy:*)";
    model = "haiku";
    effort = "low";
  };

  search-code-routing = {
    description = "Routing guide for searching code: when to reach for builtin `rg`/`grep`/Glob (literal strings, known symbols, exact paths), `ast-grep`/`sg` (structural, AST-shaped patterns and refactor-grade matches), or `gh search` (repo-wide / org-wide / not-locally-cloned). Prefer ast-grep over plain grep for anything structural; prefer builtin grep for literal text.";
    content = import ./search-code-routing.nix;
    allowed-tools = "Bash(rg:*) Bash(grep:*) Bash(ast-grep:*) Bash(sg:*) Bash(gh:*) Read Glob";
    model = "haiku";
    effort = "low";
  };

  writing-commit-message = {
    description = "Writes git commit messages in a terse, conventional-commit-shaped style. Lowercase preferred but not absolute, title-only by default, no body, no period. Supports the historical `<type>: <TICKET-ID>: <subject>` variant when a tracker ticket is in scope. Use when drafting a commit message or when the user says 'commit this' / 'propose a commit message' / 'write commit'.";
    content = import ./writing-commit-message.nix;
    model = "haiku";
    effort = "low";
  };

  writing-pr-description = {
    description = "Writes GitHub PR descriptions in a terse, opinionated style. Delegates body shape to the repo PR template when one exists; falls back to `## Summary` plus an optional ad-hoc validating-changes block. Never mutates an existing checklist. Use when drafting a `gh pr create` body, opening a PR, or when the user says 'PR body' / 'pull request description'.";
    content = import ./writing-pr-description.nix;
    model = "haiku";
    effort = "low";
  };

  writing-code-comments = {
    description = "Opinionated style for inline source-code comments. Default to no comment. Add a comment only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. No multi-paragraph docstrings. One short line max. Use when editing source files, when asked 'should I comment this', or whenever the agent considers adding a comment to code.";
    content = import ./writing-code-comments.nix;
    model = "haiku";
    effort = "low";
  };

  writing-doc-design = {
    description = "Structures a technical design doc: Summary, Goals/Non-Goals, Proposal, Design Details, Validation, Drawbacks, Alternatives, Implementation History. Section skeleton sourced from the Kubernetes KEP template, stripped of Kubernetes specifics and tuned to Roshan's working voice. Use when drafting or reviewing a design doc or technical proposal. Stores to the private Notion workspace for work tasks when the Notion MCP is available, else to a local markdown file under `.sysinit/`.";
    content = import ./writing-doc-design.nix;
  };

  writing-doc-rfc = {
    description = "Structures a request-for-comments (RFC): Summary, Motivation, Guide-level explanation, Reference-level explanation, Drawbacks, Rationale and alternatives, Prior art, Unresolved questions, Future possibilities. Section skeleton sourced from the Rust RFC template, stripped of Rust specifics and tuned to Roshan's working voice. Use when drafting or reviewing an RFC that solicits a decision. Stores to the private Notion workspace for work tasks when the Notion MCP is available, else to a local markdown file under `.sysinit/`.";
    content = import ./writing-doc-rfc.nix;
  };

  worklog = {
    description = "Generates a cross-session work report — 'what did we accomplish today' — from the append-only worklog.jsonl written by the SessionEnd hook. Drains un-summarized session entries by reading their transcripts, caches the summaries back, composes a per-day/per-repo digest, and optionally maps branches and commits to Linear/Notion/Slack outcomes. Use when the user asks what they worked on or accomplished across recent Claude Code sessions, or wants a daily or weekly progress report spanning repos.";
    content = import ./worklog.nix;
    allowed-tools = "Read Write Edit Glob Bash(jq:*) Bash(git:*) Agent";
  };

  diagram-mermaid-render = {
    description = "Renders Mermaid diagrams so they live where they are read: ASCII inline via `mermaid-ascii` for markdown, openspec artifacts, and chat; PNG/SVG export via the Kroki API only when visual fidelity is required. Per-diagram-type syntax guidance is sourced from the Agents365 mermaid-skill. Use when a diagram clarifies more than prose: capability flow, state transitions, sequence-of-calls, option trees, dependency graphs, decision points, architecture sketches.";
    content = import ./diagram-mermaid-render.nix;
    allowed-tools = "Bash(mermaid-ascii:*) Bash(curl:*) Read Write Edit";
  };
}
