import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { createWriteTool } from "@mariozechner/pi-coding-agent";
import { readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// Neovim integration for pi.
//
// Requires nvim-shim in PATH (installed via home-manager).
// Only activates when NVIM_SOCKET_PATH is set — Neovim exports it on startup
// and terminal panes spawned from within Neovim inherit it automatically.
// When the var is absent the extension is a complete no-op.
//
// write / edit tools are overridden to open a vimdiff review in Neovim:
//   Left pane  = current file on disk
//   Right pane = proposed content (read-only scratch buffer)
//
//   Per-hunk choices via vim.ui.select:
//     Accept      — apply hunk (diffget), advance
//     Reject      — skip hunk, optional reason via vim.ui.input, advance
//     Accept all  — apply remaining hunks
//     Reject all  — prompt for reason, reject the whole write
//
//   On completion nvim-shim writes a result JSON file that carries:
//     decision     — "accept" | "reject"
//     content_path — path to file with left-buffer content (accept case)
//     reason       — rejection / partial-rejection notes (optional)
//
//   Accepted: write content_path content to disk (may be partial)
//   Rejected: return reason to agent, revert buffer
//
// read tool calls open the file in the agent tab non-blocking.
// The agent tab is closed after each turn so your layout stays intact.
//
// vim.g globals for statusline integration:
//   vim.g.pi_active   — set while a pi session is live
//   vim.g.pi_running  — set while the agent is processing a turn

interface NvimPreviewResult {
  decision: "accept" | "reject";
  content_path?: string;
  reason?: string;
}

export default function (pi: ExtensionAPI) {
  let toolsRegistered = false;

  // Fire-and-forget shim call: short timeout, errors ignored.
  async function shim(...args: string[]): Promise<void> {
    try {
      await pi.exec("nvim-shim", args, { timeout: 5000 });
    } catch {
      // Neovim may have closed; ignore silently
    }
  }

  function writeTmp(content: string): string {
    const path = join(
      tmpdir(),
      `pi-preview-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    );
    writeFileSync(path, content, "utf-8");
    return path;
  }

  // Blocking vimdiff preview. Passes a result JSON path to nvim-shim;
  // nvim-shim writes the user's decision there when done.
  async function preview(
    filePath: string,
    proposedContent: string,
  ): Promise<{ accepted: boolean; content?: string; reason?: string }> {
    const tmp = writeTmp(proposedContent);
    const resultPath = join(tmpdir(), `pi-result-${Date.now()}.json`);

    try {
      await pi.exec("nvim-shim", ["preview", filePath, tmp, resultPath], {
        timeout: 130000,
      });
    } catch {
      return { accepted: false, reason: "Preview timed out" };
    } finally {
      try { unlinkSync(tmp); } catch {}
    }

    let result: NvimPreviewResult;
    try {
      result = JSON.parse(readFileSync(resultPath, "utf-8"));
      unlinkSync(resultPath);
    } catch {
      return { accepted: false, reason: "Failed to read review result" };
    }

    if (result.decision === "reject") {
      return { accepted: false, reason: result.reason };
    }

    let content: string | undefined;
    if (result.content_path) {
      try {
        content = readFileSync(result.content_path, "utf-8");
        unlinkSync(result.content_path);
      } catch {}
    }

    return { accepted: true, content, reason: result.reason };
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

        if (!result.accepted) {
          await shim("revert", filePath);
          const reason = result.reason ? `: ${result.reason}` : "";
          return {
            content: [{ type: "text", text: `Write rejected${reason}` }],
            details: {},
          };
        }

        // Write the final content — may differ from proposed if some hunks were rejected
        const finalContent = result.content ?? newContent;
        const writeParams = { ...params, content: finalContent };
        return createWriteTool(ctx.cwd).execute(
          toolCallId,
          writeParams,
          signal,
          onUpdate,
        );
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
          // Unreadable — surface the error through the write tool
          return createWriteTool(ctx.cwd).execute(
            toolCallId,
            { path: params.path, content: newText },
            signal,
            onUpdate,
          );
        }

        if (!currentContent.includes(oldText)) {
          // oldText not found — let agent know immediately, no preview needed
          return {
            content: [
              {
                type: "text",
                text: `Edit failed: oldText not found in ${params.path as string}`,
              },
            ],
            details: {},
          };
        }

        const newContent = currentContent.replace(oldText, newText);
        const result = await preview(filePath, newContent);

        if (!result.accepted) {
          await shim("revert", filePath);
          const reason = result.reason ? `: ${result.reason}` : "";
          return {
            content: [{ type: "text", text: `Edit rejected${reason}` }],
            details: {},
          };
        }

        const finalContent = result.content ?? newContent;
        return createWriteTool(ctx.cwd).execute(
          toolCallId,
          { path: params.path, content: finalContent },
          signal,
          onUpdate,
        );
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

  // --- read: open in agent tab non-blocking ---

  pi.on("tool_call", async (event) => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    if (event.toolName === "read") {
      const path = event.input.path as string | undefined;
      if (path) await shim("open", path);
    }
  });

  // --- checktime after accepted writes land on disk ---

  pi.on("tool_result", async (event) => {
    if (!process.env.NVIM_SOCKET_PATH) return;
    if (event.toolName === "write" || event.toolName === "edit") {
      await shim("checktime");
    }
  });
}
