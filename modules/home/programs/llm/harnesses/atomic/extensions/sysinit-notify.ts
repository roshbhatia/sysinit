/** Bridges atomic lifecycle events onto the shared agent notifier. */

// A type-only import, so the bundler erases it and atomic never resolves the
// package. Atomic ships its own `@bastani/atomic` types under a different name;
// the four hook names below are the ones both agents document.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Resolve a command the way a shell would, rather than naming a directory.
// `~/.nix-profile/bin` was hardcoded here and holds none of these commands on a
// nix-darwin machine, where they land in `/etc/profiles/per-user/$USER/bin`. Every
// spawn failed with ENOENT into `spawnQuiet`'s empty catch, so the bridge looked
// installed and did nothing.
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

	// `tool_result` is the post-edit surface. Atomic resolves the path for you and
	// puts it in `details.resolvedPath`, so prefer that over the relative
	// `input.path` the model supplied: an absolute path needs no assumption about
	// which directory this process is in.
	atomic.on("tool_result", (event) => {
		const name = event?.toolName ?? "";
		if (name !== "write" && name !== "edit") return;
		if (event?.isError) return;
		const resolved = event?.details?.resolvedPath;
		const path = typeof resolved === "string" && resolved !== "" ? resolved : event?.input?.path;
		if (typeof path !== "string" || path === "") return;
		spawnQuiet("agent-edit-event", [
			"atomic",
			"--file",
			path,
			"--kind",
			name,
			"--cwd",
			process.cwd(),
		]);
	});

	atomic.on("agent_settled", () => {
		state("done", "your move");
		spawnQuiet("agent-notify", ["atomic", "done", resolve("agent-focus")], "{}");
	});

	atomic.on("session_shutdown", () => {
		state("exit");
	});
}
