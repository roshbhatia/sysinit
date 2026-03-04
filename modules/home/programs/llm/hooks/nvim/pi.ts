import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createWriteTool } from "@mariozechner/pi-coding-agent";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { spawn } from "node:child_process";

// Neovim integration for pi.
//
// Requires `shim` in PATH (installed via home-manager as a uv Python script).
// Only activates when NVIM_SOCKET_PATH is set — Neovim exports it on startup
// and terminal panes spawned from within Neovim inherit it automatically.
// When absent the extension is a complete no-op.
//
// write / edit tools are overridden to open a vimdiff review in Neovim before
// any disk write. The shim speaks msgpack-rpc directly to nvim_exec_lua, which
// is a blocking RPC call — the hunk review (vim.fn.confirm / vim.fn.input)
// happens entirely inside that call, and the result comes back as JSON on
// stdout. No polling, no temp files, no race conditions.
//
// Per-hunk choices: Accept / Reject (+ optional reason) / Accept all / Reject all
// Partial acceptance is supported: only accepted hunks reach disk.
//
// vim.g globals for statusline integration:
//   vim.g.pi_active   — set while a pi session is live
//   vim.g.pi_running  — set while the agent is processing a turn

interface NvimPreviewResult {
  decision: "accept" | "reject";
  content?: string;
  reason?: string;
}

export default function (pi: ExtensionAPI) {
  let toolsRegistered = false;

  // Run the shim and await exit. stdin is optional; stdout is returned.
  function shimRun(args: string[], stdin?: string): Promise<string> {
    return new Promise((res, rej) => {
      const child = spawn("shim", args, {
        stdio: ["pipe", "pipe", "pipe"],
        env: process.env,
      });
      const out: Buffer[] = [];
      const err: Buffer[] = [];
      child.stdout.on("data", (d: Buffer) => out.push(d));
      child.stderr.on("data", (d: Buffer) => err.push(d));
      if (stdin !== undefined) child.stdin.write(stdin, "utf-8");
      child.stdin.end();
      child.on("error", rej);
      child.on("close", (code) => {
        if (code !== 0) rej(new Error(Buffer.concat(err).toString().trim() || `shim exited ${code}`));
        else res(Buffer.concat(out).toString());
      });
    });
  }

  // Fire-and-forget: run a shim command, swallow errors.
  async function shim(...args: string[]): Promise<void> {
    try { await shimRun(args); } catch { /* nvim may have closed */ }
  }

  // Blocking vimdiff review. Proposed content is sent via stdin.
  // Returns the user's decision plus the final buffer content (may be partial).
  async function preview(
    filePath: string,
    content: string,
  ): Promise<NvimPreviewResult> {
    try {
      const json = await shimRun(["preview", filePath], content);
      return JSON.parse(json) as NvimPreviewResult;
    } catch {
      return { decision: "reject", reason: "Preview failed or timed out" };
    }
  }

  function registerTools() {
    if (toolsRegistered) return;
    toolsRegistered = true;

    pi.registerTool({
      name: "write",
      label: "write",
      description:
        "Write content to a file. Creates the file if it doesn't exist, overwrites if it does. Automatically creates parent directories.",
      parameters: createWriteTool(process.cwd()).parameters,

      async execute(toolCallId, params, signal, onUpdate, ctx) {
        const filePath = resolve(ctx.cwd, params.path as string);
        const newContent = params.content as string;

        const result = await preview(filePath, newContent);

        if (result.decision === "reject") {
          await shim("revert", filePath);
          const reason = result.reason ? `: ${result.reason}` : "";
          return {
            content: [{ type: "text", text: `Write rejected${reason}` }],
            details: {},
          };
        }

        const finalContent = result.content ?? newContent;
        const writeResult = await createWriteTool(ctx.cwd).execute(
          toolCallId,
          { ...params, content: finalContent },
          signal,
          onUpdate,
        );
        // Surface partial-rejection notes back to the agent so it knows
        // which hunks were not applied and why.
        if (result.reason) {
          return {
            content: [
              ...(writeResult as { content: { type: string; text: string }[] }).content,
              { type: "text", text: `Note: some hunks were rejected — ${result.reason}` },
            ],
            details: (writeResult as { details: unknown }).details,
          };
        }
        return writeResult;
      },
    });

    pi.registerTool({
      name: "edit",
      label: "edit",
      description:
        "Edit a file by replacing exact text. The oldText must match exactly (including whitespace). Use this for precise, surgical edits.",
      parameters: createWriteTool(process.cwd()).parameters,

      async execute(toolCallId, params, signal, onUpdate, ctx) {
        const filePath = resolve(ctx.cwd, params.path as string);
        const oldText = params.oldText as string;
        const newText = params.newText as string;

        let currentContent: string;
        try {
          currentContent = readFileSync(filePath, "utf-8");
        } catch {
          return {
            content: [{ type: "text", text: `Cannot read ${params.path as string}` }],
            details: {},
          };
        }

        if (!currentContent.includes(oldText)) {
          return {
            content: [{ type: "text", text: `Edit failed: oldText not found in ${params.path as string}` }],
            details: {},
          };
        }

        const newContent = currentContent.replace(oldText, newText);
        const result = await preview(filePath, newContent);

        if (result.decision === "reject") {
          await shim("revert", filePath);
          const reason = result.reason ? `: ${result.reason}` : "";
          return {
            content: [{ type: "text", text: `Edit rejected${reason}` }],
            details: {},
          };
        }

        const finalContent = result.content ?? newContent;
        const writeResult = await createWriteTool(ctx.cwd).execute(
          toolCallId,
          { path: params.path, content: finalContent },
          signal,
          onUpdate,
        );
        if (result.reason) {
          return {
            content: [
              ...(writeResult as { content: { type: string; text: string }[] }).content,
              { type: "text", text: `Note: some hunks were rejected — ${result.reason}` },
            ],
            details: (writeResult as { details: unknown }).details,
          };
        }
        return writeResult;
      },
    });
  }

  // --- Session lifecycle: activate only when nvim socket is present ---

  pi.on("session_start", async (_event, ctx) => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    ctx.ui.setStatus("nvim", "nvim");
    await shim("set", "pi_active", "true");
    registerTools();
  });

  pi.on("session_shutdown", async () => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    await shim("close-tab");
    await shim("unset", "pi_active");
    await shim("unset", "pi_running");
  });

  pi.on("agent_start", async () => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    await shim("set", "pi_running", "true");
  });

  pi.on("agent_end", async () => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    await shim("unset", "pi_running");
    await shim("checktime");
    await shim("close-tab");
  });

  pi.on("tool_call", async (event) => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    if (event.toolName === "read") {
      const path = event.input.path as string | undefined;
      if (path) await shim("open", path);
    }
  });

  pi.on("tool_result", async (event) => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    if (event.toolName === "write" || event.toolName === "edit") {
      await shim("checktime");
    }
  });
}
