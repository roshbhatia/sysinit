import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
const frames = ["▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰", "▱▰▰", "▱▱▰"];

export default function (pi: ExtensionAPI): void {
  let animated = true;
  const running = new Map<string, string>();

  const applyIndicator = (ctx: ExtensionContext): void => {
    if (ctx.mode !== "tui") return;
    ctx.ui.setWorkingIndicator({
      frames: (animated ? frames : ["▰▰▰"]).map((frame) =>
        ctx.ui.theme.fg("accent", frame),
      ),
      intervalMs: 140,
    });
  };

  const showActivity = (ctx: ExtensionContext): void => {
    if (ctx.mode !== "tui") return;
    if (running.size === 0) {
      ctx.ui.setWorkingMessage();
      return;
    }
    const tool = running.values().next().value;
    ctx.ui.setWorkingMessage(
      running.size === 1 ? `Running ${tool}` : `Running ${running.size} tools`,
    );
  };

  pi.on("session_start", (_event, ctx) => applyIndicator(ctx));
  pi.on("agent_start", (_event, ctx) => {
    running.clear();
    applyIndicator(ctx);
    showActivity(ctx);
  });
  pi.on("tool_execution_start", (event, ctx) => {
    running.set(event.toolCallId, event.toolName);
    showActivity(ctx);
  });
  pi.on("tool_execution_end", (event, ctx) => {
    running.delete(event.toolCallId);
    showActivity(ctx);
  });
  pi.on("agent_settled", (_event, ctx) => {
    running.clear();
    showActivity(ctx);
  });

  pi.registerCommand("animation", {
    description: "Toggle the working animation: /animation [on|off]",
    handler: async (args, ctx) => {
      const value = args.trim();
      if (value && value !== "on" && value !== "off") {
        ctx.ui.notify("Usage: /animation [on|off]", "warning");
        return;
      }
      animated = value ? value === "on" : !animated;
      applyIndicator(ctx);
      ctx.ui.notify(`Working animation ${animated ? "on" : "off"}`, "info");
    },
  });
}
