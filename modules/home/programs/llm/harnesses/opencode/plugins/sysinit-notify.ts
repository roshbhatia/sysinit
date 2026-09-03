function resolve(exe: string): string {
  const { existsSync } = require("node:fs");
  for (const dir of (process.env.PATH ?? "").split(":")) {
    if (dir && existsSync(`${dir}/${exe}`)) return `${dir}/${exe}`;
  }
  return exe;
}

function spawnQuiet(exe: string, args: string[], input?: string): void {
  try {
    const { spawn } = require("node:child_process");
    const child = spawn(resolve(exe), args, {
      stdio: input === undefined ? "ignore" : ["pipe", "ignore", "ignore"],
    });
    child.on("error", () => {});
    if (input !== undefined && child.stdin) {
      child.stdin.on("error", () => {});
      child.stdin.end(input);
    }
    child.unref();
  } catch {}
}

let rootSession: string | undefined;

export const SysinitNotify = () => ({
  event: ({
    event,
  }: {
    event?: {
      type?: string;
      properties?: {
        sessionID?: string;
        status?: { type?: string };
        file?: string;
      };
    };
  }) => {
    try {
      const sid = event?.properties?.sessionID;

      if (event?.type === "file.edited") {
        const file = event?.properties?.file;
        if (file) {
          spawnQuiet("agent-edit-event", ["opencode", "--file", file]);
        }
        return;
      }

      if (event?.type === "session.created") {
        rootSession ??= sid;
        return;
      }

      if (event?.type !== "session.status") return;
      if (!sid || sid !== rootSession) return;

      switch (event?.properties?.status?.type) {
        case "idle":
          spawnQuiet("agent-state", ["opencode", "done", "your move"]);
          spawnQuiet(
            "agent-notify",
            ["opencode", "done", resolve("agent-focus")],
            "{}",
          );
          break;

        case "error":
          spawnQuiet("agent-state", ["opencode", "waiting", "session error"]);
          spawnQuiet(
            "agent-notify",
            ["opencode", "approval", resolve("agent-focus")],
            "{}",
          );
          break;

        default:
          break;
      }
    } catch {}
  },
});
