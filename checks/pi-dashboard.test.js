import { test, expect, mock } from "bun:test";
mock.module("@earendil-works/pi-tui", () => ({
  truncateToWidth: (text, width) => text.slice(0, width),
  visibleWidth: (text) => text.length,
}));
const { default: register } = await import("./dashboard.ts");

test("dashboard aliases, responsive layout, tool activity, and shutdown", async () => {
  const events = new Map();
  const commands = new Map();
  let component;
  let signal;
  const terminal = { rows: 32 };
  const pi = {
    on: (name, handler) => events.set(name, handler),
    registerCommand: (name, command) => commands.set(name, command),
    registerShortcut() {},
    exec: async (command, _args, options) => {
      signal = options.signal;
      return {
        code: 0,
        stdout: command === "git" ? " M file.ts\n" : '{"changes":[]}',
      };
    },
  };
  const context = {
    mode: "tui",
    cwd: "/fixture",
    ui: {
      notify() {},
      setWidget(_name, factory) {
        component = factory(
          { terminal, requestRender() {} },
          { fg: (_color, text) => text },
        );
      },
    },
  };
  register(pi);
  expect(commands.get("openspec-sidebar")).toBe(
    commands.get("openspec-dashboard"),
  );
  events.get("session_start")({}, context);
  try {
    await Promise.resolve();
    await Promise.resolve();
    expect(component.render(15)).toEqual([]);
    for (const width of [20, 45, 80, 120, 140]) {
      expect(
        component.render(width).every((line) => line.length <= width),
      ).toBe(true);
    }
    events.get("tool_call")({ toolCallId: "one", toolName: "edit" });
    expect(component.render(140).join("\n")).toContain("edit");
    events.get("tool_result")({ toolCallId: "one" });
    expect(component.render(140).join("\n")).toContain("Idle");
    commands.get("openspec-dashboard").handler("off", context);
    expect(component.render(140)).toEqual([]);
    commands.get("openspec-sidebar").handler("on", context);
    expect(component.render(140).length).toBe(2);
    terminal.rows = 10;
    expect(component.render(140)).toEqual([]);
  } finally {
    events.get("session_shutdown")();
  }
  expect(signal.aborted).toBe(true);
});
