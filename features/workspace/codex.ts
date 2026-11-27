import {
  mkdtempSync,
  realpathSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { reviewRefresh } from "./refresh";

interface Thread {
  id: string;
  cwd: string;
  status: { type: string };
}

interface Notification {
  method: string;
  params?: {
    threadId?: string;
    turnId?: string;
    diff?: string;
    turn?: { id: string; status: string };
  };
}

async function connect(socket: string) {
  if (!socket.startsWith("/")) {
    throw new Error("Expected an absolute Codex Unix socket path.");
  }

  const ws = new WebSocket(`ws+unix://${socket}`);
  const pending = new Map<
    number,
    (packet: { result?: unknown; error?: { message: string } }) => void
  >();
  let nextId = 0;
  const closed = new Promise<never>((_, reject) => {
    ws.addEventListener(
      "close",
      () => reject(new Error("Codex socket closed.")),
      { once: true },
    );
    ws.addEventListener(
      "error",
      () => reject(new Error(`Cannot connect to Codex socket ${socket}.`)),
      { once: true },
    );
  });
  void closed.catch(() => {});

  ws.addEventListener("message", ({ data }) => {
    const packet = JSON.parse(data);
    if (
      typeof packet.id === "number" &&
      ("result" in packet || "error" in packet)
    ) {
      pending.get(packet.id)?.(packet);
    }
  });

  async function bounded<T>(operation: string, result: Promise<T>): Promise<T> {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error(`Codex timed out during ${operation}.`)),
        15_000,
      );
    });
    try {
      return await Promise.race([result, closed, timeout]);
    } finally {
      clearTimeout(timer);
    }
  }

  async function request<T>(method: string, params: object): Promise<T> {
    const id = ++nextId;
    try {
      return await bounded(
        method,
        new Promise<T>((resolve, reject) => {
          pending.set(id, ({ result, error }) => {
            if (error) reject(new Error(`${method}: ${error.message}`));
            else resolve(result as T);
          });
          ws.send(JSON.stringify({ id, method, params }));
        }),
      );
    } finally {
      pending.delete(id);
    }
  }

  try {
    await bounded(
      "connect",
      new Promise<void>((resolve) => {
        ws.addEventListener("open", () => resolve(), { once: true });
      }),
    );
    await request("initialize", {
      clientInfo: {
        name: "sysinit-agent-workspace",
        title: "Sysinit Agent Workspace",
        version: "1.0.0",
      },
    });
    ws.send(JSON.stringify({ method: "initialized" }));
    return { request, close: () => ws.close() };
  } catch (error) {
    ws.close();
    throw error;
  }
}

function verifyThread(thread: Thread, root: string, expectedId?: string) {
  if (expectedId && thread.id !== expectedId) {
    throw new Error("Codex returned a different thread ID.");
  }
  if (realpathSync(thread.cwd) !== realpathSync(root)) {
    throw new Error(
      `Codex thread worktree ${thread.cwd} does not match ${root}.`,
    );
  }
  return thread;
}

function writeRecord(directory: string, name: string, record: object) {
  const destination = join(directory, name);
  const temporary = `${destination}.${process.pid}`;
  writeFileSync(temporary, JSON.stringify(record), { mode: 0o600 });
  renameSync(temporary, destination);
}

async function launch(
  socket: string,
  root: string,
  requestedThreadId: string,
  directory: string,
  workspaceCommand: string,
  workspaceId: string,
) {
  const proxyDirectory = mkdtempSync("/tmp/sysinit-ws-");
  const endpoint = join(proxyDirectory, "codex.sock");
  let threadId = requestedThreadId;
  let requestId: string | number | undefined;
  const refresh = reviewRefresh(directory, workspaceCommand, workspaceId);
  const diffs = new Map<string, string>();
  const activeTurn = join(directory, "active-turn.json");

  function observe({ method, params }: Notification) {
    if (!threadId || params?.threadId !== threadId) return;
    if (method === "turn/started" && params.turn) {
      writeRecord(directory, "active-turn.json", { turn_id: params.turn.id });
    }
    if (
      method === "turn/diff/updated" &&
      params.turnId &&
      typeof params.diff === "string"
    ) {
      diffs.set(params.turnId, params.diff);
    }
    if (method === "turn/completed" && params.turn) {
      const { id, status } = params.turn;
      rmSync(activeTurn, { force: true });
      const diff = diffs.get(id) ?? "";
      diffs.delete(id);
      refresh.enqueue(() => {
        writeRecord(directory, "last-turn.json", {
          version: "sysinit.codex-turn/v1",
          thread_id: threadId,
          turn_id: id,
          status,
          diff,
        });
      });
    }
  }

  // The TUI owns the protocol conversation, including approval requests.
  const server = Bun.serve<{
    upstream?: WebSocket;
    queued: (string | Buffer)[];
  }>({
    unix: endpoint,
    fetch(request, server) {
      if (server.upgrade(request, { data: { queued: [] } })) return;
      return new Response("WebSocket required", { status: 400 });
    },
    websocket: {
      idleTimeout: 0,
      maxPayloadLength: 64 * 1024 * 1024,
      open(client) {
        const upstream = new WebSocket(`ws+unix://${socket}`);
        client.data.upstream = upstream;
        upstream.onopen = () => {
          for (const payload of client.data.queued) upstream.send(payload);
          client.data.queued = [];
        };
        upstream.onmessage = ({ data }) => {
          if (typeof data === "string") {
            const packet = JSON.parse(data);
            if (
              requestId !== undefined &&
              packet.id === requestId &&
              ("result" in packet || "error" in packet)
            ) {
              requestId = undefined;
              if (packet.result?.thread) {
                try {
                  const thread = verifyThread(
                    packet.result.thread,
                    root,
                    requestedThreadId || undefined,
                  );
                  threadId = thread.id;
                  writeRecord(directory, "thread.json", {
                    thread_id: threadId,
                  });
                } catch (error) {
                  console.error(String(error));
                  client.close(1011, "Could not bind the workspace thread");
                  return;
                }
              }
            } else if (
              packet.id === undefined &&
              typeof packet.method === "string"
            ) {
              observe(packet);
            }
          }
          client.send(data);
        };
        upstream.onclose = () => client.close();
        upstream.onerror = () => {
          console.error(`Cannot connect to Codex socket ${socket}.`);
          client.close(1011, "Could not connect to Codex App Server");
        };
      },
      message(client, payload) {
        if (
          typeof payload === "string" &&
          requestId === undefined &&
          (!threadId || requestedThreadId === threadId)
        ) {
          const packet = JSON.parse(payload);
          if (
            (!threadId && packet.method === "thread/start") ||
            (packet.method === "thread/resume" &&
              packet.params?.threadId === requestedThreadId)
          ) {
            requestId = packet.id;
          }
        }
        if (client.data.upstream?.readyState === WebSocket.OPEN)
          client.data.upstream.send(payload);
        else client.data.queued.push(payload);
      },
      close(client) {
        client.data.upstream?.close();
      },
    },
  });

  try {
    const options = ["--remote", `unix://${endpoint}`, "--cd", root];
    const argv = requestedThreadId
      ? ["codex", "resume", ...options, requestedThreadId]
      : ["codex", ...options];
    const child = Bun.spawn(argv, {
      cwd: root,
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    });
    // Both processes share the terminal's foreground process group.
    process.on("SIGINT", () => {});
    for (const signal of ["SIGTERM", "SIGHUP"] as const) {
      process.on(signal, () => child.kill(signal));
    }
    process.exitCode = await child.exited;
    await refresh.finished();
  } finally {
    server.stop(true);
    rmSync(activeTurn, { force: true });
    rmSync(proxyDirectory, { recursive: true, force: true });
  }
}

async function main() {
  const [operation, socket, root, threadId, ...args] = process.argv.slice(2);
  if (operation === "run") {
    const [directory, workspaceCommand, workspaceId] = args;
    await launch(
      socket,
      root,
      threadId,
      directory,
      workspaceCommand,
      workspaceId,
    );
    return;
  }

  const rpc = await connect(socket);
  try {
    const read = async () =>
      verifyThread(
        (await rpc.request<{ thread: Thread }>("thread/read", { threadId }))
          .thread,
        root,
        threadId,
      );
    const resume = async () =>
      verifyThread(
        (
          await rpc.request<{ thread: Thread }>("thread/resume", {
            threadId,
            excludeTurns: true,
          })
        ).thread,
        root,
        threadId,
      );

    switch (operation) {
      case "bind": {
        const thread = threadId ? await read() : null;
        console.log(JSON.stringify({ thread_id: thread?.id ?? null }));
        break;
      }

      case "feedback": {
        const [expectedTurnId] = args;
        const current = await read();
        const text = await Bun.stdin.text();
        if (!text.trim()) throw new Error("Expected review feedback on stdin.");
        const input = [{ type: "text", text, text_elements: [] }];
        if (expectedTurnId) {
          const result = await rpc.request("turn/steer", {
            threadId,
            expectedTurnId,
            input,
          });
          console.log(JSON.stringify(result));
          break;
        }
        const thread =
          current.status.type === "notLoaded" ? await resume() : current;
        if (thread.status.type !== "idle") {
          throw new Error(
            "Codex thread must be idle. Use --steer with the exact active turn ID.",
          );
        }
        const result = await rpc.request<{
          turn: { id: string; status: string };
        }>("turn/start", { threadId, input });
        console.log(
          JSON.stringify({
            turn_id: result.turn.id,
            status: result.turn.status,
          }),
        );
        break;
      }

      default:
        throw new Error(`Unknown Codex workspace operation: ${operation}`);
    }
  } finally {
    rpc.close();
  }
}

try {
  await main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
