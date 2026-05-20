''
  # Diagramming

  Render diagrams as ASCII so they live inline in markdown that you and the user actually read — proposals, design notes, openspec artifacts, exploration scratch, chat replies. Write the diagram in Mermaid, render it through `mermaid-ascii`, and paste the ASCII output into the doc inside a fenced block.

  Mermaid is the source of truth; ASCII is the render. Keep the Mermaid alongside so it can be re-rendered or edited later.

  ## When to Use

  Reach for this skill whenever a diagram clarifies more than prose:

  - **OpenSpec proposals / design.md** — flow of a new capability, state transitions, sequence of calls
  - **Exploration (`/opsx:explore`, brainstorming)** — option trees, dependency graphs, decision points
  - **Investigating a bug** — sequence diagram of what is happening vs. what should happen
  - **Architecture sketches in chat** — component boundaries, data flow
  - **README / runbook diagrams** — small enough to belong in the doc, not a separate PNG

  Skip it for trivial two-box flows where prose is shorter, or for diagrams that need precise visual fidelity (rendered Mermaid via GitHub or Mermaid Live serves those better).

  ## The Tool

  Binary: `mermaid-ascii` (provided via the Nix overlay; on PATH in this environment).

  ```
  mermaid-ascii -f <file>          # render a mermaid file
  mermaid-ascii -f -                # read mermaid from stdin
  mermaid-ascii -f - -a             # ASCII-only (no extended chars)
  mermaid-ascii -f - -x 8 -y 3      # tighten horizontal / vertical padding
  ```

  Stick to `-f -` with a heredoc so the source stays visible in the transcript.

  ## Supported Mermaid Subset

  `mermaid-ascii` parses a useful but small subset. Author defensively:

  - **Use** `flowchart` / `graph` with `LR` or `TD` direction
  - **Use** plain rectangular nodes: `A[Label text]`
  - **Use** simple edges: `A --> B`, `A -->|label| B`
  - **Avoid** decision-diamond syntax (`B{Question?}`) — it renders as the literal text `B{Question?}` rather than a diamond. Use a rectangle and put the question inside: `B[Question?]`.
  - **Avoid** subgraphs, class definitions, themes, icons, and most styling — they are ignored or break parsing.
  - **Avoid** `sequenceDiagram`, `stateDiagram`, `erDiagram`, `gantt` — not supported. Model sequences as a left-to-right flowchart instead.

  When in doubt, render early and iterate. If the output looks wrong, simplify the Mermaid before reaching for flags.

  ## Standard Flow

  1. Draft the diagram in Mermaid in your head or in scratch.
  2. Pipe it through `mermaid-ascii` to verify it renders cleanly.
  3. Embed **both** in the doc: the Mermaid source in a ` ```mermaid ` block, then the ASCII render in a plain fenced block immediately after. The source lets a future reader (or you) re-render; the ASCII gives the reader something they can actually see in a terminal or plain-text view.

  Example embedding:

  ````markdown
  ```mermaid
  flowchart LR
    A[user input] --> B[parser]
    B --> C[planner]
    C --> D[executor]
  ```

  ```
  ┌────────────┐     ┌────────┐     ┌─────────┐     ┌──────────┐
  │ user input ├────►│ parser ├────►│ planner ├────►│ executor │
  └────────────┘     └────────┘     └─────────┘     └──────────┘
  ```
  ````

  ## Render Command Recipes

  Inline render in a shell:

  ```bash
  mermaid-ascii -f - <<'EOF'
  flowchart LR
    A[idea] --> B[propose]
    B --> C[apply]
    C --> D[archive]
  EOF
  ```

  Render a file already on disk (e.g., during `/opsx:propose`):

  ```bash
  mermaid-ascii -f openspec/changes/<name>/design.mmd
  ```

  ASCII-only (for environments that mangle box-drawing characters):

  ```bash
  mermaid-ascii -f - -a <<'EOF'
  flowchart TD
    A[start] --> B[end]
  EOF
  ```

  ## Authoring Tips

  - Keep node labels short — long labels widen the layout and push other nodes off-screen.
  - Prefer `LR` (left-to-right) for pipelines and `TD` (top-down) for decision trees.
  - For a yes/no fork, use two labeled edges from one rectangle: `B -->|yes| C` and `B -->|no| D`. Do not use `{?}` diamonds.
  - If the render is too wide for a terminal, drop `-x` (default 5) to 2 or 3.
  - Re-render after every meaningful edit; do not paste stale ASCII.

  ## OpenSpec Integration

  When working inside `openspec/changes/<name>/`:

  - Put the Mermaid source in `design.md` (fenced as ```` ```mermaid ````).
  - Immediately follow with the rendered ASCII in a plain fenced block.
  - If the diagram is large, save the source to `design.mmd` next to `design.md` and reference it; render fresh ASCII into `design.md` on every edit.

  ## Guardrails

  - The diagram is for human comprehension — if it does not help a reader, omit it.
  - Always render before pasting; never hand-draw ASCII boxes when `mermaid-ascii` can do it.
  - Keep the Mermaid source in the file. ASCII alone is write-only.
  - Do not depend on Mermaid features `mermaid-ascii` does not support; pick another tool (or skip the diagram) if you need them.
''
