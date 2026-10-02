import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

interface Change {
  name: string;
  completed: number;
  total: number;
  modified: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function activeChange(text: string): Change | undefined {
  const value: unknown = JSON.parse(text);
  if (!isRecord(value) || !Array.isArray(value.changes)) {
    throw new Error("Invalid OpenSpec change list");
  }
  const changes: Change[] = [];
  for (const change of value.changes) {
    if (!isRecord(change) || typeof change.name !== "string") continue;
    changes.push({
      name: change.name,
      completed:
        typeof change.completedTasks === "number" ? change.completedTasks : 0,
      total: typeof change.totalTasks === "number" ? change.totalTasks : 0,
      modified:
        typeof change.lastModified === "string" ? change.lastModified : "",
    });
  }
  return changes.sort((a, b) => b.modified.localeCompare(a.modified))[0];
}

export default function (pi: ExtensionAPI): void {
  let enabled = true;
  let columnWidth = 40;
  let spec = "Loading";
  let workspace = "Loading";
  const activeTools = new Map<string, string>();
  let redraw: (() => void) | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;
  let controller: AbortController | undefined;
  let refreshing = false;

  const stop = (): void => {
    if (timer) clearInterval(timer);
    timer = undefined;
    controller?.abort();
    controller = undefined;
    redraw = undefined;
    refreshing = false;
  };

  const refresh = async (ctx: ExtensionContext): Promise<void> => {
    const current = controller;
    if (!current || refreshing) return;
    refreshing = true;
    const options = { cwd: ctx.cwd, timeout: 2000, signal: current.signal };
    const results = await Promise.allSettled([
      pi.exec("openspec", ["list", "--json", "--no-color"], options),
      pi.exec("git", ["status", "--porcelain"], options),
    ]);
    if (controller !== current || current.signal.aborted) return;
    const [changes, files] = results;
    spec = "Unavailable in this directory";
    if (changes.status === "fulfilled" && changes.value.code === 0) {
      try {
        const change = activeChange(changes.value.stdout);
        spec = change
          ? `${change.name}  ${change.completed}/${change.total}`
          : "No active changes";
      } catch {
        spec = "Invalid OpenSpec response";
      }
    }
    workspace = "No Git repository";
    if (files.status === "fulfilled" && files.value.code === 0) {
      const count = files.value.stdout
        .split("\n")
        .filter((line) => line.length > 0).length;
      workspace = count
        ? `${count} changed file${count === 1 ? "" : "s"}`
        : "Clean";
    }
    refreshing = false;
    redraw?.();
  };

  pi.on("session_start", (_event, ctx) => {
    stop();
    activeTools.clear();
    if (ctx.mode !== "tui") return;
    ctx.ui.setWidget(
      "openspec-sidebar",
      (tui, theme) => {
        redraw = () => tui.requestRender();
        return {
          dispose: stop,
          invalidate() {},
          render(width: number): string[] {
            if (!enabled || width < 20 || tui.terminal.rows < 16) return [];
            const tools = [...activeTools.values()];
            const panels = [
              ["OpenSpec", spec],
              ["Workspace", workspace],
              ["Tools", tools.length ? tools.join(", ") : "Idle"],
            ];
            const columns = Math.min(
              panels.length,
              Math.max(1, Math.floor(width / columnWidth)),
            );
            const cell = Math.max(
              1,
              Math.floor((width - (columns - 1) * 3) / columns),
            );
            return [0, 1].map((row) =>
              panels
                .slice(0, columns)
                .map((panel) => {
                  const text = truncateToWidth(panel[row], cell, "");
                  const padded =
                    text + " ".repeat(Math.max(0, cell - visibleWidth(text)));
                  return row === 0
                    ? theme.fg("accent", padded)
                    : theme.fg("dim", padded);
                })
                .join(theme.fg("borderMuted", " │ ")),
            );
          },
        };
      },
      { placement: "belowEditor" },
    );
    controller = new AbortController();
    void refresh(ctx);
    timer = setInterval(() => void refresh(ctx), 30_000);
  });
  pi.on("session_shutdown", stop);
  pi.on("tool_call", (event) => {
    activeTools.set(event.toolCallId, event.toolName);
    redraw?.();
  });
  pi.on("tool_result", (event) => {
    activeTools.delete(event.toolCallId);
    redraw?.();
  });
  pi.on("agent_settled", (_event, ctx) => {
    activeTools.clear();
    void refresh(ctx);
    redraw?.();
  });

  const toggle = (ctx: ExtensionContext, next = !enabled): void => {
    enabled = next;
    redraw?.();
    ctx.ui.notify(`OpenSpec dashboard ${enabled ? "on" : "off"}`, "info");
  };
  pi.registerCommand("openspec-sidebar", {
    description: "Toggle the dashboard: /openspec-sidebar [on|off|width 24-60]",
    handler: (args, ctx) => {
      const [command, value] = args.trim().split(/\s+/);
      if (command === "width") {
        const width = Number(value);
        if (Number.isInteger(width) && width >= 24 && width <= 60) {
          columnWidth = width;
          redraw?.();
          return;
        }
      } else if (!command || command === "on" || command === "off") {
        toggle(ctx, command ? command === "on" : !enabled);
        return;
      }
      ctx.ui.notify("Usage: /openspec-sidebar [on|off|width 24-60]", "warning");
    },
  });
  pi.registerShortcut("shift+ctrl+b", {
    description: "Toggle the OpenSpec dashboard",
    handler: (ctx) => toggle(ctx),
  });
}
