import { appendFileSync } from "node:fs";
import { join } from "node:path";

export function reviewRefresh(directory: string, command: string, id: string) {
  let pending = Promise.resolve();

  function report(error: unknown) {
    appendFileSync(
      join(directory, "refresh.log"),
      `${new Date().toISOString()} ${error}\n`,
      { mode: 0o600 },
    );
  }

  return {
    enqueue(before?: () => void) {
      pending = pending
        .then(async () => {
          before?.();
          const child = Bun.spawn([command, "refresh", id], {
            stdin: "ignore",
            stdout: "ignore",
            stderr: "pipe",
          });
          const [status, stderr] = await Promise.all([
            child.exited,
            child.stderr.text(),
          ]);
          if (status !== 0) {
            report(stderr.trim() || `Diff refresh exited with code ${status}.`);
          }
        })
        .catch(report);
    },
    finished: () => pending,
    report,
  };
}
