import type { Plugin } from "@opencode/plugin/tui";
import { execFile } from "node:child_process";

export default {
  id: "sysinit.diff",
  setup(ctx) {
    ctx.keymap.layer(() => ({
      mode: "global",
      priority: 20,
      commands: [
        {
          id: "sysinit.diff.open",
          title: "Open Neovim diff",
          group: "Sysinit",
          palette: true,
          slash: { name: "diff" },
          run: async () => {
            const route = ctx.ui.router.current();
            const session =
              route.type === "session"
                ? ctx.data.session.get(route.sessionID)
                : undefined;
            const cwd = session?.location.directory ?? ctx.location?.directory;
            if (!cwd) {
              ctx.ui.toast.show({
                message: "No active local directory",
                variant: "error",
              });
              return;
            }
            await new Promise<void>((resolve) => {
              execFile(
                "agent-diff",
                ["--cwd", cwd],
                { timeout: 16000 },
                (error, stdout, stderr) => {
                  ctx.ui.toast.show({
                    message: (error ? stderr || error.message : stdout).trim(),
                    variant: error ? "error" : "success",
                  });
                  resolve();
                },
              );
            });
          },
        },
      ],
    }));
  },
} satisfies Plugin.Definition;
