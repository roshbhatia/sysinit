
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function resolve(exe: string): string {
	const { existsSync } = require("node:fs");
	for (const dir of (process.env.PATH ?? "").split(":")) {
		if (dir && existsSync(`${dir}/${exe}`)) return `${dir}/${exe}`;
	}
	return exe;
}

function spawnQuiet(exe: string, args: string[], input?: string): void {
	try {
		const { spawn } = require("node:child_process");
		const child = spawn(resolve(exe), args, {
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

	agent.on("agent_end", () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["prime-agent", "done", resolve("agent-focus")], "{}");
	});

	agent.on("session_shutdown", () => {
		state("exit");
	});
}
