/**
 * sysinit-notify: bridge OpenCode's event bus onto the shared agent notifier.
 *
 * OpenCode 1.18 carries its own `attention` block in `tui.json` that can raise a
 * toast and play a sound. That was one of four independent notification
 * producers in this configuration, and it cannot name the seshy session or the
 * repository. This replaces it by calling the same `agent-state` and
 * `agent-notify` executables every other harness uses.
 *
 * OpenCode 1.18 removed `experimental.hook`, so a shell hook is not available
 * and a plugin is the only surface. A probe plugin confirmed the load path:
 * OpenCode loads `.ts` files from BOTH `~/.config/opencode/plugin/` and
 * `~/.config/opencode/plugins/`, and its own onboarding text names
 * `.opencode/plugins/` for event hooks with OS notifications as the use case.
 *
 * The bridge only spawns. Classification, suppression, identity, icons, and
 * sounds stay in the shell scripts, so there is one copy of that logic.
 *
 * Best-effort by contract: every spawn is wrapped and every failure swallowed.
 * A notifier problem must never fail an OpenCode session.
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
		// Degrade to no notification, never to a failed session.
	}
}

export const SysinitNotify = async () => ({
	event: async ({ event }: { event?: { type?: string } }) => {
		try {
			switch (event?.type) {
				// The run finished and OpenCode is waiting on the human.
				case "session.idle":
					spawnQuiet("agent-state", ["opencode", "done", "your move"]);
					spawnQuiet("agent-notify", ["opencode", "done", `${BIN}/agent-focus`], "{}");
					break;

				// The run stopped on an error, which also needs the human.
				case "session.error":
					spawnQuiet("agent-state", ["opencode", "waiting", "session error"]);
					spawnQuiet("agent-notify", ["opencode", "approval", `${BIN}/agent-focus`], "{}");
					break;

				default:
					break;
			}
		} catch {
			// An unexpected event shape must not propagate into OpenCode.
		}
	},
});
