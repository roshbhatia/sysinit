/** Bridges prime-agent lifecycle events onto the shared agent notifier. */

// A type-only import, so the bundler erases it. prime-agent does provide
// `@earendil-works/pi-coding-agent` to an extension at runtime as a virtual
// module, but nothing here needs a value from it.
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
	spawnQuiet(
		"agent-state",
		reason === undefined ? ["prime-agent", status] : ["prime-agent", status, reason],
	);
}

export default function (agent: ExtensionAPI) {
	agent.on("session_start", () => {
		state("working", "session start");
	});

	agent.on("tool_call", (event) => {
		const name = event?.toolName ?? "";
		const args = (event?.input ?? {}) as Record<string, unknown>;
		// prime-agent's three built-in tools are bash, edit, and ipython, keyed
		// `command`, `path`, and `code` respectively (see ToolCallEvent in
		// dist/core/extensions/types.d.ts). There is no read, grep, or find tool:
		// prime-agent reaches files through bash and ipython instead, so the pi
		// and atomic spellings of those arguments are not worth carrying. The
		// trailing keys cover a custom tool contributed by a loaded package.
		const detail =
			args.command ??
			args.code ??
			args.path ??
			args.file_path ??
			args.pattern ??
			args.description ??
			"";
		const reason = name && detail ? `${name}: ${detail}` : name || "working";
		state("working", String(reason));
	});

	// `agent_end`, not `turn_end`: turn_end fires once per turn, so it would
	// notify repeatedly while the agent is still working. prime-agent has no
	// `agent_settled` event, which is the name pi and atomic use for this.
	agent.on("agent_end", () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["prime-agent", "done", `${BIN}/agent-focus`], "{}");
	});

	agent.on("session_shutdown", () => {
		state("exit");
	});
}
