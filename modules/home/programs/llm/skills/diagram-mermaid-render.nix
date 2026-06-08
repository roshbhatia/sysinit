''
  # Diagramming

  Diagrams live where they are read. Default to **ASCII inline** so a diagram
  survives in markdown, openspec artifacts, terminals, and chat without an asset
  pipeline. Reach for a **rendered image** (PNG/SVG) only when visual fidelity
  earns its keep — a diagram type ASCII cannot express, or a doc that ships to a
  rendering surface (a published page, a PR that renders Mermaid, a slide).

  Mermaid is always the source of truth. ASCII or image is the render. Keep the
  Mermaid alongside the render so it can be edited and re-rendered later.

  Provenance: the per-diagram-type syntax guidance below is distilled from the
  Agents365 `mermaid-skill` (`Agents365-ai/mermaid-skill`,
  `skills/mermaid-skill/SKILL.md`). The opinions layered on top — ASCII-first,
  Kroki over a local Puppeteer/mmdc toolchain, the supported-subset guardrails —
  are this repository's own.

  ## When to use

  Reach for a diagram whenever it clarifies more than prose:

  - **OpenSpec proposals / design.md** — capability flow, state transitions,
    sequence of calls.
  - **Exploration / brainstorming** — option trees, dependency graphs, decision
    points.
  - **Investigating a bug** — sequence of what happens vs. what should.
  - **Architecture sketches in chat** — component boundaries, data flow.
  - **README / runbook** — small enough to belong inline, not a separate asset.

  Skip it for trivial two-box flows where prose is shorter.

  ## Decide the render target first

  ```
  if the diagram is a flowchart/graph AND lands in markdown, openspec, or chat
    -> ASCII inline via mermaid-ascii   (the default — no assets, always legible)
  elif the diagram needs a type ASCII can't express (sequence, state, ER, gantt,
       class, pie, mindmap) OR ships to a rendering surface
    -> image via the Kroki HTTP API     (curl; no local mmdc/Puppeteer)
  ```

  Prefer ASCII. Only escalate to an image when the target genuinely needs it.

  ## Path A — ASCII inline (default)

  Binary: `mermaid-ascii` (provided via the Nix overlay; on PATH here).

  ```
  mermaid-ascii -f <file>        # render a mermaid file
  mermaid-ascii -f -             # read mermaid from stdin
  mermaid-ascii -f - -a          # ASCII-only (no extended box chars)
  mermaid-ascii -f - -x 8 -y 3   # tighten horizontal / vertical padding
  ```

  Use `-f -` with a heredoc so the source stays visible in the transcript.

  ### Supported subset

  `mermaid-ascii` parses a useful but small subset. Author defensively:

  - **Use** `flowchart` / `graph` with `LR` or `TD` direction.
  - **Use** plain rectangular nodes: `A[Label text]`.
  - **Use** simple edges: `A --> B`, `A -->|label| B`.
  - **Avoid** decision-diamond syntax (`B{Question?}`) — it renders as literal
    text. Use a rectangle: `B[Question?]`, fork with two labeled edges.
  - **Avoid** subgraphs, class defs, themes, icons, styling — ignored or broken.
  - **Avoid** `sequenceDiagram`, `stateDiagram`, `erDiagram`, `gantt`, `pie` —
    not supported here. Either model the flow as a left-to-right flowchart, or
    escalate to Path B for a faithful render.

  ### Embed both source and render

  Put the Mermaid source in a ` ```mermaid ` block, then the ASCII render in a
  plain fenced block immediately after. The source re-renders; the ASCII is what
  a plain-text reader sees.

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

  ### Recipes

  ```bash
  mermaid-ascii -f - <<'EOF'
  flowchart LR
    A[idea] --> B[propose]
    B --> C[apply]
    C --> D[archive]
  EOF
  ```

  ```bash
  mermaid-ascii -f openspec/changes/<name>/design.mmd   # file on disk
  mermaid-ascii -f - -a <<'EOF'                          # ASCII-only fallback
  flowchart TD
    A[start] --> B[end]
  EOF
  ```

  ## Path B — image export via Kroki (fidelity)

  When ASCII cannot carry the diagram, render through the Kroki HTTP API with
  `curl`. This avoids a local `mmdc` / Puppeteer / headless-Chrome toolchain
  entirely — Kroki takes Mermaid text and returns an SVG or PNG.

  ```bash
  # SVG (preferred — scalable, diff-able, smaller)
  curl -s -X POST https://kroki.io/mermaid/svg \
    --data-binary @diagram.mmd -o diagram.svg

  # PNG (when the target only accepts a raster image)
  curl -s -X POST https://kroki.io/mermaid/png \
    --data-binary @diagram.mmd -o diagram.png
  ```

  Guardrails for Path B:

  - Kroki is a network call to an external service. State that the diagram source
    is being sent off-box before doing it, and never send anything sensitive in
    the diagram text.
  - Keep the `.mmd` source in the repo next to the exported asset.
  - Default to SVG; reach for PNG only when the destination cannot embed SVG.

  ## Per-diagram-type syntax (distilled from mermaid-skill)

  Pick the type that matches the relationship. For flowchart/graph, render via
  Path A; for the rest, render via Path B.

  - **flowchart** — process/decision flow. `flowchart LR` or `TD`; nodes
    `A[rect]`, `A(round)`, `A{diamond}`; edges `-->`, `-->|label|`, `-.->`.
  - **sequenceDiagram** — ordered messages between actors over time.
    `participant A`; `A->>B: call`; `B-->>A: reply`; `loop`/`alt`/`opt` blocks.
  - **stateDiagram-v2** — lifecycle / state machine. `[*] --> Idle`;
    `Idle --> Running: start`; nested `state X { ... }`.
  - **erDiagram** — data model. `CUSTOMER ||--o{ ORDER : places` (crow's-foot
    cardinality).
  - **classDiagram** — types and relationships. `class Foo { +field; +method() }`;
    `Foo <|-- Bar` (inheritance), `Foo o-- Baz` (aggregation).
  - **gantt** — schedule. `dateFormat YYYY-MM-DD`; sections; `task :id, start, dur`.
  - **pie** — proportions. `pie title T` then `"Label" : value` rows.
  - **mindmap** — hierarchical brainstorm. `mindmap` then indented nodes.

  Authoring rules that apply across types: keep node labels short; quote labels
  containing spaces or punctuation when a parser complains; one relationship per
  line; render early and iterate rather than authoring a large diagram blind.

  ## Authoring tips (Path A)

  - Short labels — long ones widen the layout and push nodes off-screen.
  - `LR` for pipelines, `TD` for decision trees.
  - Yes/no fork: two labeled edges from one rectangle (`B -->|yes| C`,
    `B -->|no| D`), never a `{?}` diamond.
  - If too wide for a terminal, drop `-x` (default 5) to 2 or 3.
  - Re-render after every meaningful edit; never paste stale ASCII.

  ## OpenSpec integration

  - Put the Mermaid source in `design.md` (fenced ```` ```mermaid ````), then the
    rendered ASCII in a plain fenced block right after.
  - Large diagram: save source to `design.mmd` beside `design.md`, reference it,
    and render fresh ASCII into `design.md` on every edit.

  ## Guardrails

  - The diagram is for human comprehension — if it does not help a reader, omit.
  - Always render before pasting; never hand-draw ASCII boxes.
  - Keep the Mermaid source in the file. A render alone is write-only.
  - Stay inside the `mermaid-ascii` subset for Path A; escalate to Path B (Kroki)
    rather than forcing an unsupported type into ASCII.
''
