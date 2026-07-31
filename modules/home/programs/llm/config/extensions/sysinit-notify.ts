/**
 * sysinit-notify: bridge pi's lifecycle onto the shared agent notifier.
 *
 * Pi shipped its own `notify` extension, which wrote an OSC 777 sequence. That
 * was one of four independent notification producers in this configuration, and
 * it carried no session, no repository, and no icon. This replaces it by calling
 * the same `agent-state` and `agent-notify` executables every hooked harness
 * uses, so one producer announces every agent.
 *
 * The bridge deliberately does nothing but spawn. Classification, suppression,
 * identity resolution, icons, and sounds all live in the shell scripts. A second
 * copy of that logic here is the exact drift this consolidation removes.
 *
 * Event choice matters. `agent_settled`, not `agent_end`, marks the done
 * transition: pi's own docs state that `agent_end` fires while pi may still
 * auto-retry, auto-compact, or run a queued follow-up, and direct a status
 * integration to `agent_settled`. Wiring `agent_end` would raise a premature
 * done toast, which is the defect this work exists to remove.
 *
 * Best-effort by contract, matching the shell scripts: every spawn is wrapped,
 * every failure is swallowed, and no handler ever rejects. A notifier problem
 * must never fail a pi turn.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? "";
const BIN = `${HOME}/.nix-profile/bin`;

/**
 * Spawn a helper and forget it. Detached with stdio ignored so a slow or hung
 * notifier cannot hold pi's event loop, and every throw is swallowed.
 */
function spawnQuiet(exe: string, args: string[], input?: string): void {
	try {
		const { spawn } = require("node:child_process");
		const child = spawn(`${BIN}/${exe}`, args, {
			detached: true,
			stdio: input === undefined ? "ignore" : ["pipe", "ignore", "ignore"],
		});
		child.on("error", () => {});
		if (input !== undefined && child.stdin) {
			child.stdin.on("error", () => {});
			child.stdin.end(input);
		}
		child.unref();
	} catch {
		// A missing binary, a spawn failure, or a runtime without child_process
		// all degrade to no notification. Never to a failed turn.
	}
}

function state(status: string, reason?: string): void {
	spawnQuiet("agent-state", reason === undefined ? ["pi", status] : ["pi", status, reason]);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async () => {
		state("working", "session start");
	});

	// The tool name and its most telling input become the reason string the
	// statusline shows, matching what Claude's PreToolUse hook emits.
	pi.on("tool_call", async (event: any) => {
		const name = event?.toolName ?? event?.tool?.name ?? "";
		const args = event?.args ?? event?.arguments ?? {};
		const detail = args.command ?? args.file_path ?? args.path ?? args.pattern ?? "";
		const reason = name && detail ? `${name}: ${detail}` : name || "working";
		state("working", reason);
	});

	// Settled, not ended: pi will not continue on its own from here.
	pi.on("agent_settled", async () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["pi", "done", `${BIN}/agent-focus`], "{}");
	});

	// Terminal transition: drop this pane's entry from the cross-surface bus.
	pi.on("session_shutdown", async () => {
		state("exit");
	});
}
