import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

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

function state(status: string, reason?: string): void {
  spawnQuiet(
    "agent-state",
    reason === undefined ? ["pi", status] : ["pi", status, reason],
  );
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", () => {
    state("working", "session start");
  });

  pi.on("tool_call", (event) => {
    const name = event?.toolName ?? "";
    const args = event?.input ?? {};
    const detail =
      args.command ??
      args.file_path ??
      args.path ??
      args.description ??
      args.pattern ??
      "";
    const reason = name && detail ? `${name}: ${detail}` : name || "working";
    state("working", reason);
  });

  pi.on("tool_result", (event) => {
    const name = event?.toolName ?? "";
    if (name !== "write" && name !== "edit") return;
    if (event?.isError) return;
    const path = event?.input?.path;
    if (typeof path !== "string" || path === "") return;
    spawnQuiet("agent-edit-event", [
      "pi",
      "--file",
      path,
      "--kind",
      name,
      "--cwd",
      process.cwd(),
    ]);
  });

  pi.on("agent_settled", () => {
    state("done", "your move");
    spawnQuiet("agent-notify", ["pi", "done", resolve("agent-focus")], "{}");
  });

  pi.on("session_shutdown", () => {
    state("exit");
  });
}
