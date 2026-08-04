/** Bridges pi lifecycle events onto the shared agent notifier. */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? "";
const BIN = `${HOME}/.nix-profile/bin`;

function spawnQuiet(exe: string, args: string[], input?: string): void {
	try {
		const { spawn } = require("node:child_process");
		// detached children lose the tty that `agent-state` uses for OSC
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
	pi.on("session_start", () => {
		state("working", "session start");
	});

	pi.on("tool_call", (event) => {
		const name = event?.toolName ?? "";
		// `event.input`, not `event.args`: the latter belongs to tool_execution_*
		const args = event?.input ?? {};
		const detail =
			args.command ?? args.file_path ?? args.path ?? args.description ?? args.pattern ?? "";
		const reason = name && detail ? `${name}: ${detail}` : name || "working";
		state("working", reason);
	});

	// `agent_settled`, not `agent_end`: pi may still auto-retry or compact
	pi.on("agent_settled", () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["pi", "done", `${BIN}/agent-focus`], "{}");
	});

	pi.on("session_shutdown", () => {
		state("exit");
	});
}
