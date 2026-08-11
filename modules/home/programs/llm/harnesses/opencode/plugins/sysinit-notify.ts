/** Bridges OpenCode events onto the shared agent notifier. */

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

// child sessions share this bus, so only root transitions represent the user's turn
let rootSession: string | undefined;

export const SysinitNotify = () => ({
	event: ({
		event,
	}: {
		event?: {
			type?: string;
			properties?: {
				sessionID?: string;
				status?: { type?: string };
				file?: string;
			};
		};
	}) => {
		try {
			const sid = event?.properties?.sessionID;

			// `file.edited` is a purpose-built post-edit event carrying one absolute
			// path, so this needs no tool name and no correlation. It fires for every
			// editing tool, `apply_patch` included, which is why the patch envelope
			// codex has to parse is irrelevant here.
			if (event?.type === "file.edited") {
				const file = event?.properties?.file;
				if (file) {
					spawnQuiet("agent-edit-event", ["opencode", "--file", file]);
				}
				return;
			}

			if (event?.type === "session.created") {
				rootSession ??= sid;
				return;
			}

			if (event?.type !== "session.status") return;
			if (!sid || sid !== rootSession) return;

			switch (event?.properties?.status?.type) {
				case "idle":
					spawnQuiet("agent-state", ["opencode", "done", "your move"]);
					spawnQuiet("agent-notify", ["opencode", "done", resolve("agent-focus")], "{}");
					break;

				case "error":
					spawnQuiet("agent-state", ["opencode", "waiting", "session error"]);
					spawnQuiet("agent-notify", ["opencode", "approval", resolve("agent-focus")], "{}");
					break;

				default:
					break;
			}
		} catch {
		}
	},
});
