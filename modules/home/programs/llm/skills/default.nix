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
    description = "Decides which code-search tool a query needs, in preference order: `ast-grep outline` to map structure before reading, `ast-grep`/`sg` for code shapes, `rg`/`grep`/Glob only for literal text, `gh search` for repos not cloned locally. Use when starting a search and the right tool is not obvious. Dispatches to the `ast-grep-outline` and `ast-grep` skills for how to run those two.";
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
    description = "Structures a technical design doc from the Kubernetes KEP skeleton: Summary, Goals/Non-Goals, Proposal, Design Details, Validation, Drawbacks, Alternatives. Use when drafting or reviewing a design doc or technical proposal.";
    content = import ./writing-doc-design.nix;
  };

  writing-doc-rfc = {
    description = "Structures a request-for-comments from the Rust RFC skeleton: Motivation, Guide-level and Reference-level explanation, Drawbacks, Alternatives, Prior art. Use when drafting or reviewing an RFC that solicits a decision.";
    content = import ./writing-doc-rfc.nix;
  };

  writing-tone = {
    description = "Rewrites longer-form prose into Roshan's working voice: scope-bounded, contract-shaped, terse. Use for audit docs, proposals, design notes, RFCs, status posts, and review comments written in his name.";
    content = import ./writing-tone.nix;
    model = "haiku";
    effort = "low";
  };

  worklog = {
    description = "Generates a cross-session work report from worklog.jsonl, digested per day and per repo. Use when the user asks what they worked on or accomplished recently, or wants a daily or weekly progress report spanning repos.";
    content = import ./worklog.nix;
    allowed-tools = "Read Write Edit Glob Bash(bash:*) Bash(jq:*) Bash(git:*) Agent";
    files = {
      "scripts/worklog-query.sh" = ./scripts/worklog-query.sh;
    };
  };

  adversarial-review = {
    description = "Runs an adversarial review loop: independent critics try to break an artifact and the author revises against surviving objections. Use at the rosh-spec-driven review gate, before marking a tasks.md slice done, or when asked to red-team a plan, spec, or design.";
    content = import ./adversarial-review.nix;
    allowed-tools = "Agent Read Grep Glob Bash(printenv:*) Bash(env:*) Bash(openspec:*)";
    files = {
      "references/adversarial-review-methodology.md" = ./references/adversarial-review-methodology.md;
    };
  };

  citation-verification = {
    description = "Verify external-factual claims (pricing, availability, external API behavior, cited papers) deterministically with `citelock`: pin each claim into a citations.lock against a tool-captured snapshot, so the offline gate is a pure function and `citelock capture` fails closed on a quote a live source does not state. Use when authoring a rosh-spec-driven change with external-factual claims; the schema makes an unanchored claim a default-reject.";
    content = import ./citation-verification.nix;
    allowed-tools = "Bash(citelock:*) Read";
  };

  diagram-mermaid-render = {
    description = "Renders Mermaid diagrams so they live where they are read: ASCII inline via `mermaid-ascii` for markdown, openspec artifacts, and chat; PNG/SVG export via the Kroki API only when visual fidelity is required. Per-diagram-type syntax guidance is sourced from the Agents365 mermaid-skill. Use when a diagram clarifies more than prose: capability flow, state transitions, sequence-of-calls, option trees, dependency graphs, decision points, architecture sketches.";
    content = import ./diagram-mermaid-render.nix;
    allowed-tools = "Bash(mermaid-ascii:*) Bash(curl:*) Read Write Edit";
  };

  specutil = {
    description = "Uses specutil (on PATH) to visualize and plan OpenSpec changes. Run before planning multi-change work to see the cross-change DAG, surface blockers, and preview Linear/Notion sync operations without network I/O. Use when the user asks about openspec change status, wants to see a dependency graph, explore or plan spec-driven work, render a change as RFC/design/tickets, or preview sync to Linear/Notion.";
    content = import ./specutil.nix;
    allowed-tools = "Bash(specutil:*) Bash(mermaid-ascii:*)";
  };

  openspec-workflow = {
    description = "Uses the global OpenSpec workflow for spec-driven repositories without relying on per-project openspec init scaffolding. Use when a task mentions OpenSpec, proposals, designs, specs, tasks, or named changes, and prefer the Explore planning subagent for discovery before implementation.";
    content = import ./openspec-workflow.nix;
    allowed-tools = "Bash(openspec:*) Bash(specutil:*) Read Glob";
  };

  pplx-cli = {
    description = "Uses the Perplexity CLI (`pplx`) for general external web research: live web search and page-content fetch returning structured JSON. Auth-conditional: use pplx only when authenticated (`PERPLEXITY_API_KEY` set or a `pplx auth login` credentials file), otherwise fall back to the built-in WebSearch/WebFetch. Never send internal, private, or in-repo content to pplx. Use when doing external/public web research, not for internal docs or private data.";
    content = import ./pplx-cli.nix;
    allowed-tools = "Bash(pplx:*)";
  };
}
