import type { Plugin } from "@opencode/plugin";
import { resolve } from "node:path";
import { spawnQuiet } from "./sysinit-process.ts";

export default {
  id: "sysinit.edits",
  async setup(ctx) {
    await ctx.tool.hook("execute.after", async (event) => {
      if (
        event.status !== "completed" ||
        !["edit", "write", "patch"].includes(event.tool)
      )
        return;
      const files = event.result.metadata?.files;
      if (!Array.isArray(files)) return;
      const session = await ctx.session.get({ sessionID: event.sessionID });
      const cwd = session.location.directory;
      for (const file of files) {
        if (
          !file ||
          typeof file !== "object" ||
          !("file" in file) ||
          typeof file.file !== "string"
        )
          continue;
        spawnQuiet(
          "gate",
          [
            "hook",
            "--harness",
            "json",
            "--event",
            "PostToolUse",
            "--format",
            "json",
          ],
          JSON.stringify({
            version: "gate.event/v1",
            harness: "opencode",
            event: "PostToolUse",
            tool: event.tool === "write" ? "Write" : "Edit",
            input: { file_path: resolve(cwd, file.file) },
            cwd,
          }),
        );
      }
    });
  },
} satisfies Plugin.Plugin;
