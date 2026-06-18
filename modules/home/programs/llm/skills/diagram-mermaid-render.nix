''
  # Diagramming

  Diagrams live where they are read. Default to **ASCII inline** so a diagram
  survives in markdown, openspec artifacts, terminals, and chat without an asset
  pipeline. Reach for a **rendered image** (PNG/SVG) only when fidelity earns it —
  a diagram type ASCII cannot express, or a doc that ships to a rendering surface.

  Mermaid is always the source of truth; ASCII or image is the render. Keep the
  Mermaid alongside the render so it can be edited and re-rendered later.

  Provenance: per-diagram-type syntax below is distilled from the Agents365
  `mermaid-skill` (`Agents365-ai/mermaid-skill`). The opinions on top — ASCII-first,
  Kroki over a local Puppeteer/mmdc toolchain, the subset guardrails — are this
  repository's own.

  ## Decision routing — pick the render target first

  ```
  Flowchart/graph landing in markdown, openspec, or chat?              -> ASCII inline via mermaid-ascii (default)
  Type ASCII can't express (sequence, state, ER, gantt, class, pie)
    OR shipping to a rendering surface (published page, slide)?         -> image via Kroki HTTP API (curl)
  Trivial two-box flow shorter as prose?                                -> skip the diagram
  ```

  Prefer ASCII; escalate to an image only when the target genuinely needs it.

  ## When a diagram earns its place

  Reach for one when it clarifies more than prose: capability flow, state
  transitions, sequence-of-calls (openspec proposals/design.md); option trees,
  dependency graphs, decision points (exploration); what-happens-vs-should (bugs);
  component boundaries (architecture sketches); small inline visuals (README).

  ## Path A — ASCII inline (default)

  Binary: `mermaid-ascii` (on PATH via the Nix overlay). Use `-f -` with a heredoc
  so the source stays visible in the transcript.

  ```bash
  mermaid-ascii -f <file>        # render a mermaid file
  mermaid-ascii -f -             # read mermaid from stdin
  mermaid-ascii -f - -a          # ASCII-only (no extended box chars)
  mermaid-ascii -f - -x 8 -y 3   # tighten horizontal / vertical padding
  ```

  ### Stay inside the supported subset — good vs bad

  `mermaid-ascii` parses a small subset. Author defensively:

  ```
  # good — flowchart/graph, LR or TD, plain rect nodes, simple/labeled edges
  flowchart LR
    A[user input] --> B[parser]
    B -->|ok| C[planner]
    B -->|err| D[reject]

  # bad — renders as literal text or breaks
  flowchart LR
    B{Question?}              <- decision diamond: use a rectangle B[Question?] + two labeled edges
    subgraph cluster ... end  <- subgraphs, classDefs, themes, icons, styling: ignored or broken
  sequenceDiagram             <- unsupported here: model as an LR flowchart or escalate to Path B
  ```

  ### Embed both source and render

  Put the Mermaid in a ` ```mermaid ` block, then the ASCII render in a plain fenced
  block immediately after. The source re-renders; the ASCII is what a plain-text
  reader sees.

  ````markdown
  ```mermaid
  flowchart LR
    A[user input] --> B[parser]
    B --> C[planner]
  ```

  ```
  ┌────────────┐     ┌────────┐     ┌─────────┐
  │ user input ├────►│ parser ├────►│ planner │
  └────────────┘     └────────┘     └─────────┘
  ```
  ````

  ## Path B — image export via Kroki (fidelity)

  When ASCII cannot carry the diagram, render through Kroki with `curl` — no local
  `mmdc` / Puppeteer / headless-Chrome toolchain.

  ```bash
  # SVG (preferred — scalable, diff-able, smaller)
  curl -s -X POST https://kroki.io/mermaid/svg --data-binary @diagram.mmd -o diagram.svg
  # PNG (only when the target cannot embed SVG)
  curl -s -X POST https://kroki.io/mermaid/png --data-binary @diagram.mmd -o diagram.png
  ```

  Kroki is a network call to an external service. State that the diagram source is
  being sent off-box before doing it, never send anything sensitive in the diagram
  text, and keep the `.mmd` source in the repo next to the exported asset.

  ## Per-diagram-type syntax (distilled from mermaid-skill)

  Pick the type that matches the relationship. Flowchart/graph -> Path A; the rest
  -> Path B.

  - **flowchart** — process/decision flow. `flowchart LR|TD`; `A[rect]`, `A(round)`,
    `A{diamond}`; edges `-->`, `-->|label|`, `-.->`.
  - **sequenceDiagram** — ordered messages. `participant A`; `A->>B: call`;
    `B-->>A: reply`; `loop`/`alt`/`opt` blocks.
  - **stateDiagram-v2** — lifecycle. `[*] --> Idle`; `Idle --> Running: start`.
  - **erDiagram** — data model. `CUSTOMER ||--o{ ORDER : places`.
  - **classDiagram** — types. `class Foo { +field; +method() }`; `Foo <|-- Bar`.
  - **gantt** — schedule. `dateFormat YYYY-MM-DD`; sections; `task :id, start, dur`.
  - **pie** — proportions. `pie title T` then `"Label" : value` rows.
  - **mindmap** — hierarchical brainstorm. `mindmap` then indented nodes.

  Across types: short labels; quote labels with spaces/punctuation when a parser
  complains; one relationship per line; render early and iterate.

  ## OpenSpec integration

  - Put the Mermaid source in `design.md` (fenced ```` ```mermaid ````), then the
    rendered ASCII in a plain fenced block right after.
  - Large diagram: save source to `design.mmd` beside `design.md`, reference it, and
    render fresh ASCII into `design.md` on every edit.

  ## Guardrails

  - The diagram is for human comprehension — if it does not help a reader, omit.
  - Always render before pasting; never hand-draw ASCII boxes or paste stale ASCII.
  - Keep the Mermaid source in the file. A render alone is write-only.
  - Stay inside the `mermaid-ascii` subset for Path A; escalate to Path B rather
    than forcing an unsupported type into ASCII.
''
