import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const frames = ["▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰", "▱▰▰", "▱▱▰"];

export default function (pi: ExtensionAPI): void {
  let animated = true;
  const apply = (ctx: ExtensionContext): void => {
    if (ctx.mode !== "tui") return;
    ctx.ui.setWorkingIndicator({
      frames: (animated ? frames : ["▰▰▰"]).map((frame) =>
        ctx.ui.theme.fg("accent", frame),
      ),
      intervalMs: 140,
    });
    ctx.ui.setHeader((_tui, theme) => ({
      invalidate() {},
      render(width: number) {
        return [
          truncateToWidth(
            theme.bold(theme.fg("accent", " pi ")) +
              theme.fg("dim", " /model  /tools  /session"),
            width,
          ),
        ];
      },
    }));
  };
  pi.on("session_start", (_event, ctx) => apply(ctx));
  pi.on("agent_start", (_event, ctx) => apply(ctx));
  pi.registerCommand("animation", {
    description: "Toggle the working animation: /animation [on|off]",
    handler: (args, ctx) => {
      const value = args.trim();
      if (value && value !== "on" && value !== "off") {
        ctx.ui.notify("Usage: /animation [on|off]", "warning");
        return;
      }
      animated = value ? value === "on" : !animated;
      apply(ctx);
      ctx.ui.notify(`Working animation ${animated ? "on" : "off"}`, "info");
    },
  });
}
