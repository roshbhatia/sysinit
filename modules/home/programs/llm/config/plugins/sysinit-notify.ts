/**
 * Bridges OpenCode's event bus onto the shared agent notifier.
 *
 * Only spawns; classification, suppression, identity, icons, and sounds live in
 * the shell scripts so there is one copy of that logic.
 */

const HOME = process.env.HOME ?? "";
const BIN = `${HOME}/.nix-profile/bin`;

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
		// no `detached`: setsid() severs the controlling terminal, so
		// agent-state's `> /dev/tty` OSC never lands and the pane looks hookless
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
		// degrade to no notification, never to a failed session
	}
}

// a subagent runs in its own child session on the same bus, so only the root's
// transitions are the human's turn
let rootSession: string | undefined;

export const SysinitNotify = async () => ({
	event: async ({
		event,
	}: {
		event?: {
			type?: string;
			properties?: { sessionID?: string; status?: { type?: string } };
		};
	}) => {
		try {
			const sid = event?.properties?.sessionID;

			if (event?.type === "session.created") {
				rootSession ??= sid;
				return;
			}

			// turn end is `session.status` with type "idle"; there is no
			// `session.idle` event delivered to plugins
			if (event?.type !== "session.status") return;
			if (!sid || sid !== rootSession) return;

			switch (event?.properties?.status?.type) {
				case "idle":
					spawnQuiet("agent-state", ["opencode", "done", "your move"]);
					spawnQuiet("agent-notify", ["opencode", "done", `${BIN}/agent-focus`], "{}");
					break;

				case "error":
					spawnQuiet("agent-state", ["opencode", "waiting", "session error"]);
					spawnQuiet("agent-notify", ["opencode", "approval", `${BIN}/agent-focus`], "{}");
					break;

				// busy, retry, waiting are mid-run
				default:
					break;
			}
		} catch {
			// an unexpected event shape must not propagate into OpenCode
		}
	},
});
