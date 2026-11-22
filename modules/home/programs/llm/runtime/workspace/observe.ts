import { appendFileSync, watch, type FSWatcher } from "node:fs";
import { join } from "node:path";

const [root, review, directory, workspaceCommand, workspaceId, ...argv] =
  process.argv.slice(2);
let timer: ReturnType<typeof setTimeout> | undefined;
let refresh = Promise.resolve();
const settle = 750;

function log(details: string) {
  appendFileSync(
    join(directory, "refresh.log"),
    `${new Date().toISOString()} ${details}\n`,
    { mode: 0o600 },
  );
}

function refreshReview() {
  refresh = refresh
    .then(async () => {
      const child = Bun.spawn([workspaceCommand, "refresh", workspaceId], {
        stdin: "ignore",
        stdout: "ignore",
        stderr: "pipe",
      });
      const [status, stderr] = await Promise.all([
        child.exited,
        child.stderr.text(),
      ]);
      if (status !== 0) log(stderr.trim());
    })
    .catch((error) => log(String(error)));
}

function observeChanges(_type: string, filename: string | Buffer | null) {
  if (filename?.toString().split("/").includes(".git")) return;
  clearTimeout(timer);
  timer = setTimeout(() => {
    timer = undefined;
    refreshReview();
  }, settle);
}

let watcher: FSWatcher | undefined;
try {
  watcher = watch(root, { recursive: true }, observeChanges);
  watcher.on("error", (error) => {
    log(`Workspace file watcher: ${error.message}`);
    watcher?.close();
  });
} catch (error) {
  log(`Workspace file watcher: ${error}`);
}

const agent = Bun.spawn(argv, {
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
});
process.on("SIGINT", () => {});
for (const signal of ["SIGTERM", "SIGHUP"] as const) {
  process.on(signal, () => agent.kill(signal));
}

process.exitCode = await agent.exited;
await Bun.sleep(settle);
watcher?.close();
if (timer !== undefined || review === "git") {
  clearTimeout(timer);
  refreshReview();
}
await refresh;
