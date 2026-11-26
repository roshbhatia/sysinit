import { serve, spawn } from "bun";
import { expect, test } from "bun:test";
import { Blob } from "node:buffer";
import {
  chmodSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { env } from "node:process";

test("workspace review runs even when a command edits and immediately exits", async () => {
  const directory = mkdtempSync("/tmp/sysinit-watch-");
  const root = join(directory, "project");
  const refresh = join(directory, "refresh");
  const marker = join(directory, "refreshed");
  mkdirSync(root);
  writeFileSync(refresh, `#!/bin/sh\nprintf '%s\\n' "$@" > "${marker}"\n`);
  chmodSync(refresh, 0o700);

  try {
    const command = spawn([
      "bun",
      "./workspace-observe.ts",
      root,
      "git",
      directory,
      refresh,
      "workspace-id",
      "/bin/sh",
      "-c",
      'printf "%s\\n" changed > "$1/file.txt"',
      "write-file",
      root,
    ]);
    expect(await command.exited).toBe(0);
    expect(readFileSync(join(root, "file.txt"), "utf8")).toBe("changed\n");
    expect(readFileSync(marker, "utf8")).toBe("refresh\nworkspace-id\n");
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test("Codex workspace binds, watches, and sends to the exact thread", async () => {
  const directory = mkdtempSync("/tmp/sysinit-ws-");
  const socket = join(directory, "app.sock");
  const calls = [];
  const thread = {
    id: "workspace-thread",
    cwd: directory,
    status: { type: "idle" },
  };
  const server = serve({
    unix: socket,
    fetch(request, server) {
      if (server.upgrade(request)) return;
      return new globalThis.Response("WebSocket required", { status: 400 });
    },
    websocket: {
      message(connection, message) {
        const { id, method, params } = JSON.parse(message);
        if (id === undefined) return;
        calls.push({ method, params });
        const result =
          {
            "thread/start": { thread },
            "thread/read": { thread },
            "thread/resume": { thread },
            "turn/start": {
              turn: { id: "feedback-turn", status: "inProgress" },
            },
            "turn/steer": { turnId: "expected-turn" },
          }[method] ?? {};
        connection.send(JSON.stringify({ id, result }));
        if (method === "thread/start" || method === "thread/resume") {
          for (const [threadId, turnId, diff] of [
            [thread.id, "completed-turn", "workspace patch"],
            ["unrelated-thread", "ignored-turn", "unrelated patch"],
          ]) {
            connection.send(
              JSON.stringify({
                method: "turn/diff/updated",
                params: { threadId, turnId, diff },
              }),
            );
            connection.send(
              JSON.stringify({
                method: "turn/completed",
                params: { threadId, turn: { id: turnId, status: "completed" } },
              }),
            );
          }
        }
      },
    },
  });

  function script(name, body) {
    const file = join(directory, name);
    writeFileSync(file, `#!/bin/sh\n${body}\n`);
    chmodSync(file, 0o700);
    return file;
  }

  async function run(
    operation,
    id,
    args = [],
    { cwd = directory, stdin } = {},
  ) {
    const child = spawn(
      ["bun", "./workspace-codex.ts", operation, socket, cwd, id, ...args],
      {
        env: { ...env, PATH: `${directory}:${env.PATH}` },
        stdin: stdin ? new Blob([stdin]) : "ignore",
        stdout: "pipe",
        stderr: "pipe",
      },
    );
    const [code, stdout, stderr] = await Promise.all([
      child.exited,
      child.stdout.text(),
      child.stderr.text(),
    ]);
    return { code, stdout, stderr };
  }

  try {
    const bound = await run("bind", thread.id);
    expect(bound.code).toBe(0);
    expect(JSON.parse(bound.stdout).thread_id).toBe(thread.id);

    const wrongDirectory = await run("bind", thread.id, [], { cwd: "/tmp" });
    expect(wrongDirectory.code).toBe(1);
    expect(wrongDirectory.stderr).toContain("does not match");
    const wrongThread = await run("bind", "other-thread");
    expect(wrongThread.code).toBe(1);

    const fakeTui = join(directory, "fake-tui.js");
    writeFileSync(
      fakeTui,
      `
      const args = process.argv.slice(2);
      await Bun.write("invocation", JSON.stringify(args));
      const endpoint = args[args.indexOf("--remote") + 1];
      const ws = new WebSocket(endpoint.replace(/^unix:/, "ws+unix:"));
      ws.onopen = () => {
        const id = 1;
        if (args[0] === "resume") {
          ws.send(JSON.stringify({id, method: "thread/resume", params: {threadId: args.at(-1)}}));
        } else {
          ws.send(JSON.stringify({id, method: "thread/start", params: {cwd: args[args.indexOf("--cd") + 1]}}));
        }
      };
      ws.onmessage = ({data}) => {
        const packet = JSON.parse(data);
        if (packet.params?.threadId === "unrelated-thread" && packet.method === "turn/completed") ws.close();
      };
    `,
    );
    script("codex", `exec bun "${fakeTui}" "$@"`);
    const refreshCommand = script(
      "refresh",
      `printf '%s\\n' "$@" > "${join(directory, "refreshed")}"`,
    );
    const watched = await run("run", "", [
      directory,
      refreshCommand,
      "workspace-id",
    ]);
    expect(watched.code).toBe(0);
    const invocation = JSON.parse(
      readFileSync(join(directory, "invocation"), "utf8"),
    );
    expect(invocation).toEqual([
      "--remote",
      expect.stringMatching(/^unix:/),
      "--cd",
      directory,
    ]);
    expect(
      JSON.parse(readFileSync(join(directory, "thread.json"), "utf8")),
    ).toEqual({ thread_id: thread.id });
    expect(
      JSON.parse(readFileSync(join(directory, "last-turn.json"), "utf8")),
    ).toMatchObject({
      thread_id: thread.id,
      turn_id: "completed-turn",
      diff: "workspace patch",
    });
    expect(readFileSync(join(directory, "refreshed"), "utf8")).toBe(
      "refresh\nworkspace-id\n",
    );
    const resumed = await run("run", thread.id, [
      directory,
      refreshCommand,
      "workspace-id",
    ]);
    expect(resumed.code).toBe(0);
    expect(
      JSON.parse(readFileSync(join(directory, "invocation"), "utf8")),
    ).toEqual([
      "resume",
      "--remote",
      expect.stringMatching(/^unix:/),
      "--cd",
      directory,
      thread.id,
    ]);

    const feedback = await run("feedback", thread.id, [""], {
      stdin: "Review note.",
    });
    expect(feedback.code).toBe(0);
    expect(JSON.parse(feedback.stdout).turn_id).toBe("feedback-turn");
    const steer = await run("feedback", thread.id, ["expected-turn"], {
      stdin: "Steer this turn.",
    });
    expect(steer.code).toBe(0);
    expect(calls.filter(({ method }) => method.startsWith("turn/"))).toEqual([
      {
        method: "turn/start",
        params: {
          threadId: thread.id,
          input: [{ type: "text", text: "Review note.", text_elements: [] }],
        },
      },
      {
        method: "turn/steer",
        params: {
          threadId: thread.id,
          expectedTurnId: "expected-turn",
          input: [
            { type: "text", text: "Steer this turn.", text_elements: [] },
          ],
        },
      },
    ]);
    thread.status.type = "active";
    const active = await run("feedback", thread.id, [""], {
      stdin: "Review note.",
    });
    expect(active.code).toBe(1);
    expect(active.stderr).toContain("exact active turn ID");
  } finally {
    server.stop(true);
    rmSync(directory, { recursive: true, force: true });
  }
});
