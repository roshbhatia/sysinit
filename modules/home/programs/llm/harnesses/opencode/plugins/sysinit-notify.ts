import type { Plugin } from "@opencode/plugin/tui";
import { resolveExecutable, spawnQuiet } from "./sysinit-process.ts";

export default {
  id: "sysinit.notify",
  setup(ctx) {
    function owns(sessionID: string): boolean {
      const root = ctx.data.session.root(sessionID);
      const route = ctx.ui.router.current();
      return (
        (route.type === "session" && route.sessionID === root) ||
        ctx.ui.tabs.list().some((tab) => tab.sessionID === root)
      );
    }

    function notify(sessionID: string, failed: boolean): void {
      if (!owns(sessionID)) return;
      spawnQuiet("agent-state", [
        "opencode",
        failed ? "waiting" : "done",
        failed ? "needs attention" : "your move",
      ]);
      spawnQuiet(
        "agent-notify",
        [
          "opencode",
          failed ? "approval" : "done",
          resolveExecutable("agent-focus"),
        ],
        "{}",
      );
    }

    const stops = [
      ctx.data.on("session.idle", (event) => {
        if (
          ctx.data.session.root(event.data.sessionID) === event.data.sessionID
        )
          notify(event.data.sessionID, false);
      }),
      ctx.data.on("permission.asked", (event) =>
        notify(event.data.sessionID, true),
      ),
      ctx.data.on("session.execution.failed", (event) =>
        notify(event.data.sessionID, true),
      ),
    ];
    return () => stops.forEach((stop) => stop());
  },
} satisfies Plugin.Definition;
