/** Bridges OpenCode events onto the shared agent notifier. */

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

// child sessions share this bus, so only root transitions represent the user's turn
let rootSession: string | undefined;

export const SysinitNotify = () => ({
	event: ({
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

				default:
					break;
			}
		} catch {
		}
	},
});
