import { watch, type FSWatcher } from "node:fs";
import { reviewRefresh } from "./refresh";

const [root, review, directory, workspaceCommand, workspaceId, ...argv] =
  process.argv.slice(2);
let timer: ReturnType<typeof setTimeout> | undefined;
const refresh = reviewRefresh(directory, workspaceCommand, workspaceId);
const settle = 750;

function observeChanges(_type: string, filename: string | Buffer | null) {
  if (filename?.toString().split("/").includes(".git")) return;
  clearTimeout(timer);
  timer = setTimeout(() => {
    timer = undefined;
    refresh.enqueue();
  }, settle);
}

let watcher: FSWatcher | undefined;
try {
  watcher = watch(root, { recursive: true }, observeChanges);
  watcher.on("error", (error) => {
    refresh.report(`Workspace file watcher: ${error.message}`);
    watcher?.close();
  });
} catch (error) {
  refresh.report(`Workspace file watcher: ${error}`);
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
  refresh.enqueue();
}
await refresh.finished();
