import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const CACHE_TTL_MS = 5_000;
const EXEC_TIMEOUT_MS = 2_000;
const MIN_COLUMNS = 70;
const SIDEBAR_ID = "openspec-sidebar";

interface Theme {
  fg(name: string, text: string): string;
  bold(text: string): string;
}

interface Terminal {
  columns: number;
  rows: number;
  write(data: string): void;
}

interface Tui {
  terminal: Terminal;
  doRender?: () => void;
  requestRender?(): void;
}

interface WidgetUi {
  setWidget(
    id: string,
    factory: (tui: Tui, theme: Theme) => {
      dispose(): void;
      invalidate(): void;
      render(width: number): string[];
    },
    options: { placement: "belowEditor" },
  ): void;
  notify?(message: string, level: "info" | "warning"): void;
}

interface RuntimeContext {
  cwd?: string;
  hasUI?: boolean;
  ui?: WidgetUi;
}

interface OpenSpecArtifact {
  id: string;
  status: string;
}

interface OpenSpecChange {
  name: string;
  artifacts: OpenSpecArtifact[];
  completedTasks?: number;
  totalTasks?: number;
}

interface SidebarState {
  changes: OpenSpecChange[];
  unavailable: boolean;
}

interface CachedState {
  state: SidebarState;
  at: number;
}

let enabled = true;
let sidebarWidth = 36;
let cache: CachedState | undefined;

function runtimeContext(ctx: ExtensionContext): RuntimeContext {
  return ctx as unknown as RuntimeContext;
}

function withTimeout<T>(promise: Promise<T>): Promise<T | undefined> {
  return Promise.race([
    promise,
    new Promise<undefined>((resolve) => setTimeout(resolve, EXEC_TIMEOUT_MS)),
  ]);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function parseChangeNames(json: string): string[] | undefined {
  try {
    const parsed: unknown = JSON.parse(json);
    if (!isRecord(parsed) || !Array.isArray(parsed.changes)) return undefined;
    return parsed.changes.flatMap((change) => {
      if (!isRecord(change) || typeof change.name !== "string" || change.name.length === 0) return [];
      return [change.name];
    });
  } catch {
    return undefined;
  }
}

function parseArtifacts(json: string): OpenSpecArtifact[] {
  try {
    const parsed: unknown = JSON.parse(json);
    if (!isRecord(parsed) || !Array.isArray(parsed.artifacts)) return [];
    return parsed.artifacts.flatMap((artifact) => {
      if (!isRecord(artifact) || typeof artifact.id !== "string" || typeof artifact.status !== "string") return [];
      return [{ id: artifact.id, status: artifact.status }];
    });
  } catch {
    return [];
  }
}

async function taskProgress(cwd: string | undefined, name: string): Promise<Pick<OpenSpecChange, "completedTasks" | "totalTasks">> {
  if (!cwd) return {};
  try {
    const tasks = await readFile(join(cwd, "openspec", "changes", name, "tasks.md"), "utf8");
    const totalTasks = (tasks.match(/^\s*- \[[ xX]\] /gm) ?? []).length;
    const completedTasks = (tasks.match(/^\s*- \[[xX]\] /gm) ?? []).length;
    return totalTasks > 0 ? { completedTasks, totalTasks } : {};
  } catch {
    return {};
  }
}

async function readState(pi: ExtensionAPI, cwd: string | undefined): Promise<SidebarState> {
  const listed = await withTimeout(pi.exec("openspec", ["list", "--json", "--no-color"]));
  if (!listed || listed.code !== 0) return { changes: [], unavailable: true };
  const names = parseChangeNames(listed.stdout);
  if (!names) return { changes: [], unavailable: true };

  const changes = await Promise.all(
    names.map(async (name) => {
      const status = await withTimeout(pi.exec("openspec", ["status", "--change", name, "--json", "--no-color"]));
      const artifacts = status && status.code === 0 ? parseArtifacts(status.stdout) : [];
      return { name, artifacts, ...(await taskProgress(cwd, name)) };
    }),
  );
  return { changes, unavailable: false };
}

async function refresh(pi: ExtensionAPI, cwd: string | undefined): Promise<SidebarState> {
  if (cache && Date.now() - cache.at < CACHE_TTL_MS) return cache.state;
  const state = await readState(pi, cwd);
  cache = { state, at: Date.now() };
  return state;
}

function reset(): string {
  return "\x1b[22;23;24;39m";
}

function style(theme: Theme, color: string, text: string): string {
  return theme.fg(color, text) + reset();
}

function truncate(text: string, width: number): string {
  return visibleWidth(text) > width ? truncateToWidth(text, width, "", true) : text;
}

function renderSidebar(state: SidebarState, theme: Theme, width: number): string[] {
  const lines = [theme.bold(style(theme, "accent", " OpenSpec")), style(theme, "dim", "─".repeat(width))];
  if (state.unavailable) return [...lines, style(theme, "dim", "  unavailable")];
  if (state.changes.length === 0) return [...lines, style(theme, "dim", "  no active changes")];

  for (const change of state.changes) {
    lines.push(style(theme, "text", `  ${truncate(change.name, Math.max(1, width - 2))}`));
    if (change.totalTasks !== undefined && change.completedTasks !== undefined) {
      const color = change.completedTasks === change.totalTasks ? "success" : "warning";
      lines.push(style(theme, "dim", "    tasks ") + style(theme, color, `${change.completedTasks}/${change.totalTasks}`));
    }
    for (const artifact of change.artifacts) {
      const color = artifact.status === "complete" ? "success" : artifact.status === "blocked" ? "error" : "warning";
      lines.push(style(theme, "dim", `    ${artifact.id} `) + style(theme, color, artifact.status));
    }
  }
  return lines;
}

function descriptorFor(object: object, key: string): PropertyDescriptor | undefined {
  let target: object | null = object;
  while (target) {
    const descriptor = Object.getOwnPropertyDescriptor(target, key);
    if (descriptor) return descriptor;
    target = Object.getPrototypeOf(target);
  }
  return undefined;
}

class SidebarCompositor {
  private readonly terminal: Terminal;
  private readonly originalColumns: PropertyDescriptor | undefined;
  private readonly originalRender: (() => void) | undefined;
  private disposed = false;

  constructor(
    private readonly tui: Tui,
    private readonly theme: Theme,
    private readonly state: () => SidebarState,
    private readonly width: number,
  ) {
    this.terminal = tui.terminal;
    this.originalColumns = descriptorFor(this.terminal, "columns");
    this.originalRender = tui.doRender;
  }

  install(): void {
    const terminal = this.terminal;
    const columns = this.originalColumns;
    const width = this.width;
    Object.defineProperty(terminal, "columns", {
      configurable: true,
      enumerable: true,
      get() {
        const raw = columns?.get ? columns.get.call(terminal) : columns?.value;
        return Math.max(1, (typeof raw === "number" ? raw : 80) - width - 1);
      },
    });
    if (!this.originalRender) return;
    this.tui.doRender = () => {
      this.originalRender?.call(this.tui);
      this.paint();
    };
  }

  paint(): void {
    if (this.disposed) return;
    const rawColumns = this.originalColumns?.get
      ? this.originalColumns.get.call(this.terminal)
      : this.originalColumns?.value;
    const columns = typeof rawColumns === "number" ? rawColumns : 80;
    if (columns < MIN_COLUMNS) return;
    const separatorColumn = columns - this.width;
    const sidebarColumn = separatorColumn + 1;
    const lines = renderSidebar(this.state(), this.theme, this.width);
    let output = "\x1b[?2026h\x1b7\x1b[?7l";
    for (let row = 1; row <= this.terminal.rows; row++) {
      output += `\x1b[${row};${separatorColumn}H${style(this.theme, "dim", "│")}`;
      output += `\x1b[${row};${sidebarColumn}H`;
      output += row <= lines.length ? truncate(lines[row - 1], this.width) : " ".repeat(this.width);
    }
    output += "\x1b[?7h\x1b8\x1b[?2026l";
    this.terminal.write(output);
  }

  dispose(): void {
    this.disposed = true;
    if (this.originalColumns) Object.defineProperty(this.terminal, "columns", this.originalColumns);
    else Reflect.deleteProperty(this.terminal, "columns");
    if (this.originalRender) this.tui.doRender = this.originalRender;
  }
}

export default function (pi: ExtensionAPI): void {
  let compositor: SidebarCompositor | undefined;
  let latestState: SidebarState = { changes: [], unavailable: false };
  let currentContext: RuntimeContext | undefined;
  let tui: Tui | undefined;
  let theme: Theme | undefined;

  const installCompositor = (): void => {
    compositor?.dispose();
    compositor = undefined;
    if (!enabled || !tui || !theme || tui.terminal.columns < MIN_COLUMNS) return;
    compositor = new SidebarCompositor(tui, theme, () => latestState, sidebarWidth);
    compositor.install();
  };

  const update = async (ctx: ExtensionContext): Promise<void> => {
    currentContext = runtimeContext(ctx);
    latestState = await refresh(pi, currentContext.cwd);
    compositor?.paint();
  };

  pi.on("session_start", async (_event, ctx) => {
    const runtime = runtimeContext(ctx);
    currentContext = runtime;
    if (!runtime.hasUI || !runtime.ui) return;
    await update(ctx);
    runtime.ui.setWidget(SIDEBAR_ID, (nextTui, nextTheme) => {
      tui = nextTui;
      theme = nextTheme;
      installCompositor();
      return {
        dispose() {
          compositor?.dispose();
          compositor = undefined;
          tui = undefined;
          theme = undefined;
        },
        invalidate() {},
        render() {
          return [];
        },
      };
    }, { placement: "belowEditor" });
  });

  pi.on("turn_end", async (_event, ctx) => {
    await update(ctx);
  });

  pi.registerCommand("openspec-sidebar", {
    description: "Control OpenSpec sidebar: /openspec-sidebar on | off | width <N>",
    handler: async (args, ctx) => {
      const runtime = runtimeContext(ctx);
      const [command, value] = (args?.trim() ?? "").split(/\s+/, 2);
      if (command === "width") {
        const width = Number.parseInt(value ?? "", 10);
        if (!Number.isInteger(width) || width < 24 || width > 60) {
          runtime.ui?.notify?.("Usage: /openspec-sidebar width <24-60>", "warning");
          return;
        }
        sidebarWidth = width;
      } else if (command === "on" || command === "off") {
        enabled = command === "on";
      } else {
        runtime.ui?.notify?.("Usage: /openspec-sidebar on | off | width <N>", "warning");
        return;
      }
      installCompositor();
      runtime.ui?.notify?.(`OpenSpec sidebar ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });
}
