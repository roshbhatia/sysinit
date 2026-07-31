/**
 * Bridges pi's lifecycle onto the shared agent notifier.
 *
 * Only spawns; classification, suppression, identity, icons, and sounds live in
 * the shell scripts so there is one copy of that logic.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? "";
const BIN = `${HOME}/.nix-profile/bin`;

// Best-effort: a notifier failure must never fail a pi turn.
function spawnQuiet(exe: string, args: string[], input?: string): void {
	try {
		const { spawn } = require("node:child_process");
		// No `detached`. On POSIX that calls setsid(), which makes the child a
		// session leader with NO controlling terminal, so agent-state's
		// `> /dev/tty` OSC write fails and the pane's agent_state user-var is
		// never set. The WezTerm scrape bridge skips a pane only when that
		// user-var is present, so a detached spawn would make every bridged
		// harness announce twice. `unref()` alone already releases the parent
		// event loop, which is all this needs.
		const child = spawn(`${BIN}/${exe}`, args, {
			stdio: input === undefined ? "ignore" : ["pipe", "ignore", "ignore"],
		});
		child.on("error", () => {});
		if (input !== undefined && child.stdin) {
			child.stdin.on("error", () => {});
			child.stdin.end(input);
		}
		child.unref();
	} catch {
		// degrade to no notification, never to a failed turn
	}
}

function state(status: string, reason?: string): void {
	spawnQuiet("agent-state", reason === undefined ? ["pi", status] : ["pi", status, reason]);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async () => {
		state("working", "session start");
	});

	pi.on("tool_call", async (event: any) => {
		const name = event?.toolName ?? "";
		// `event.input`, not `event.args`: the latter belongs to tool_execution_*
		const args = event?.input ?? {};
		const detail =
			args.command ?? args.file_path ?? args.path ?? args.description ?? args.pattern ?? "";
		const reason = name && detail ? `${name}: ${detail}` : name || "working";
		state("working", reason);
	});

	// `agent_settled`, not `agent_end`: pi may still auto-retry or compact
	pi.on("agent_settled", async () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["pi", "done", `${BIN}/agent-focus`], "{}");
	});

	pi.on("session_shutdown", async () => {
		state("exit");
	});
}
