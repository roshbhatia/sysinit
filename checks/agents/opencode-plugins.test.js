import { beforeEach, expect, mock, test } from "bun:test";
import process from "node:process";

const calls = [];
const hooks = {};
const listeners = new Map();
const removed = [];
const define = (plugin) => plugin;
mock.module("@opencode/plugin", () => ({ Plugin: { define } }));
mock.module("@opencode/plugin/tui", () => ({ Plugin: { define } }));
mock.module(`${process.env.OPENCODE_PLUGIN_DIR}/sysinit-process.ts`, () => ({
  resolveExecutable: (name) => `/bin/${name}`,
  spawnQuiet: (...args) => calls.push(args),
}));
const notify = (
  await import(`${process.env.OPENCODE_PLUGIN_DIR}/sysinit-notify.ts`)
).default;
const edits = (
  await import(`${process.env.OPENCODE_PLUGIN_DIR}/plugins/sysinit-edits.ts`)
).default;
const context = {
  data: {
    session: { root: (id) => (id === "child" ? "resumed" : id) },
    on: (name, callback) => {
      listeners.set(name, callback);
      return () => removed.push(name);
    },
  },
  ui: {
    router: { current: () => ({ type: "session", sessionID: "resumed" }) },
    tabs: { list: () => [{ sessionID: "tab" }] },
  },
};
beforeEach(() => {
  calls.length = 0;
  removed.length = 0;
  listeners.clear();
});

test("resumed sessions notify without a session.created event", () => {
  const cleanup = notify.setup(context);
  listeners.get("session.idle")({ data: { sessionID: "resumed" } });
  expect(calls[0]).toEqual(["agent-state", ["opencode", "done", "your move"]]);
  expect(calls[1][1]).toEqual(["opencode", "done", "/bin/agent-focus"]);
  cleanup();
  expect(removed).toHaveLength(3);
});

test("other terminal sessions and child idle events cannot mark this pane done", () => {
  notify.setup(context);
  listeners.get("session.idle")({ data: { sessionID: "foreign" } });
  listeners.get("session.idle")({ data: { sessionID: "child" } });
  expect(calls).toHaveLength(0);
});

test("owned child permissions and background tab failures request attention", () => {
  notify.setup(context);
  listeners.get("permission.asked")({ data: { sessionID: "child" } });
  listeners.get("session.execution.failed")({ data: { sessionID: "tab" } });
  expect(
    calls.filter(([name]) => name === "agent-state").map(([, args]) => args[1]),
  ).toEqual(["waiting", "waiting"]);
});

test("successful patches emit each changed path in the session directory", async () => {
  await edits.setup({
    tool: {
      hook: async (name, callback) => {
        hooks[name] = callback;
      },
    },
    session: {
      get: async () => ({ location: { directory: "/work/feature" } }),
    },
  });
  await hooks["execute.after"]({
    status: "completed",
    tool: "patch",
    sessionID: "resumed",
    result: {
      metadata: { files: [{ file: "one.go" }, { file: "/work/two.go" }, null] },
    },
  });
  const events = calls.map(([, , input]) => JSON.parse(input));
  expect(events.map((event) => event.input.file_path)).toEqual([
    "/work/feature/one.go",
    "/work/two.go",
  ]);
  expect(
    events.every(
      (event) => event.cwd === "/work/feature" && event.tool === "Edit",
    ),
  ).toBe(true);
});

test("failed edits and unrelated tools emit no attribution", async () => {
  await edits.setup({
    tool: {
      hook: async (name, callback) => {
        hooks[name] = callback;
      },
    },
  });
  await hooks["execute.after"]({ status: "error", tool: "edit" });
  await hooks["execute.after"]({ status: "completed", tool: "shell" });
  expect(calls).toHaveLength(0);
});
