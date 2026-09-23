import { existsSync } from "node:fs";
import { spawn } from "node:child_process";

export function resolveExecutable(exe: string): string {
  for (const dir of (process.env.PATH ?? "").split(":")) {
    if (dir && existsSync(`${dir}/${exe}`)) return `${dir}/${exe}`;
  }
  return exe;
}

export function spawnQuiet(exe: string, args: string[], input?: string): void {
  const child = spawn(resolveExecutable(exe), args, {
    stdio: input === undefined ? "ignore" : ["pipe", "ignore", "ignore"],
  });
  child.on("error", (error) =>
    console.error(`sysinit: ${exe}: ${error.message}`),
  );
  if (input !== undefined && child.stdin) {
    child.stdin.on("error", (error) =>
      console.error(`sysinit: ${exe}: ${error.message}`),
    );
    child.stdin.end(input);
  }
  child.unref();
}
