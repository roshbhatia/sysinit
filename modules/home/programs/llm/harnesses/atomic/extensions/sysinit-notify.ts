/** Bridges atomic lifecycle events onto the shared agent notifier. */

// A type-only import, so the bundler erases it and atomic never resolves the
// package. Atomic ships its own `@bastani/atomic` types under a different name;
// the four hook names below are the ones both agents document.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? "";
const BIN = `${HOME}/.nix-profile/bin`;

function spawnQuiet(exe: string, args: string[], input?: string): void {
	try {
		const { spawn } = require("node:child_process");
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
	}
}

function state(status: string, reason?: string): void {
	spawnQuiet("agent-state", reason === undefined ? ["atomic", status] : ["atomic", status, reason]);
}

export default function (atomic: ExtensionAPI) {
	atomic.on("session_start", () => {
		state("working", "session start");
	});

	atomic.on("tool_call", (event) => {
		const name = event?.toolName ?? "";
		const args = event?.input ?? {};
		// `paths` and `pattern` come first for atomic: its `find` and `search`
		// tools carry those rather than pi's `path` and `file_path`.
		const detail =
			args.command ??
			args.paths ??
			args.pattern ??
			args.file_path ??
			args.path ??
			args.description ??
			"";
		const reason = name && detail ? `${name}: ${detail}` : name || "working";
		state("working", reason);
	});

	atomic.on("agent_settled", () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["atomic", "done", `${BIN}/agent-focus`], "{}");
	});

	atomic.on("session_shutdown", () => {
		state("exit");
	});
}
