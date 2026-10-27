---
name: conductor
description: Author, validate, run, and inspect Microsoft Conductor YAML workflows locally. Use for workflow composition, local dashboards, Taskwarrior/Pueue submission, and project MCP integration.
---

# Microsoft Conductor

Use the Nix-managed `conductor` command. The package includes the web dashboard,
Fleet TUI, Claude Agent SDK, and OpenTelemetry support. Microsoft distributes
`conductor-cli` through GitHub releases; the PyPI name belongs to another project.
Update the Nix source and lock instead of running a self-installer.

## Compose and run

Keep workflow YAML with its repository. Use native script steps, MCP steps,
subworkflows, and routing before adding orchestration code. Inspect the workflow's
prompts, tools, commands, inputs, and output contract before running it.

```sh
conductor validate workflows/workflow.yaml
conductor run workflows/workflow.yaml --dry-run
conductor run workflows/workflow.yaml --workspace-instructions
conductor --silent run workflows/workflow.yaml --workspace-instructions
```

`--silent` is a root option and produces the JSON result. Run inside the project's
Nix shell when workflow commands need project dependencies.

When invoked from an agent, find the current harness's `context` path in
`~/.config/sysinit/agents.json`, expand `~`, and also pass that file through
`--instructions /absolute/global-instructions.md`. Workspace discovery supplies
repository rules; the explicit file supplies shared working rules, including
Taskwarrior intake. Carry the task UUID, authorized scope, and acceptance criteria
in the workflow's inputs and prompts.

Check provider readiness with `conductor doctor providers --provider copilot --check`.
The package uses the installed Copilot CLI. `claude-agent-sdk` is experimental and
requires a Claude Code subscription login; installing its SDK does not authenticate
it. API providers require their own credentials. Conductor's `openai` provider
does not reuse Codex OAuth. Invoke installed clients such as Codex or Goose through
native script steps when their CLI authentication is the desired interface.
Verify each client's noninteractive flags before authoring the step.

## Queue and inspect

Read the `taskwarrior` skill before submitting a task-linked execution. Keep the
workflow in the foreground so Pueue observes its actual completion:

```sh
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  conductor run /absolute/repository/workflows/workflow.yaml \
  --workspace-instructions --instructions /absolute/global-instructions.md
```

Use `--web` for a foreground run with a dashboard. `--web-bg` detaches and returns
before the workflow finishes, so do not use it as a queued command's completion
signal. Inspect `task-queue status`, the Pueue log, and the workflow's outputs
before recording verified completion.

`conductor fleet` opens the TUI. `conductor fleet list` and `conductor status --json`
inspect runs. Cancel a specific run with `conductor stop --run-id <run-id>`.
Bare `conductor stop` can stop the only running workflow; use `status` for inspection.

## Project MCP

Use a project-scoped server with explicit discovery and execution directories:

```sh
conductor mcp serve --workflow-dir /absolute/repository/workflows \
  --launch-dir /absolute/repository
```

`--workflow-dir` adds local workflows to the catalogue; configured registries can
also contribute tools. Inspect the exposed tools before connecting a host.
`--launch-dir` fixes the execution directory at startup. Other hosts cannot be
assumed to inherit Copilot's process-based directory detection. Restart the server
when its workspace changes. Avoid a global gateway instance with an implicit cwd.

MCP launches are detached. An accepted launch is not a completed workflow; inspect
its terminal state and outputs before completing its Taskwarrior task.

Reference the installed help and the upstream
[CLI reference](https://github.com/microsoft/conductor/blob/v0.1.42/docs/cli-reference.md)
and [MCP server guide](https://github.com/microsoft/conductor/blob/v0.1.42/docs/mcp-server.md)
when authoring workflows or configuring additional providers.
