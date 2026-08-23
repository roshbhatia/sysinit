// Copilot has no declarative shell hook, only JS handlers, so this shim is what
// lets the shared guard binary reach it. @guard@ is replaced with a store path
// at build time: resolving from PATH would let a shadowed binary disarm it.
//
// The guard reads a Claude-shaped PreToolUse event on stdin and exits 2 with the
// reason on stderr when it denies. Any other exit means allow.
import { spawnSync } from "node:child_process";
import { joinSession } from "@github/copilot-sdk/extension";

const GUARD = "@guard@";

function commandOf(toolArgs) {
	if (!toolArgs || typeof toolArgs !== "object") return undefined;
	const candidate = toolArgs.command ?? toolArgs.script ?? toolArgs.cmd;
	return typeof candidate === "string" && candidate !== "" ? candidate : undefined;
}

joinSession({
	hooks: {
		onPreToolUse: (input) => {
			const command = commandOf(input?.toolArgs);
			if (command === undefined) return;

			const result = spawnSync(GUARD, [], {
				input: JSON.stringify({ tool_input: { command } }),
				encoding: "utf8",
			});

			// A guard that failed to run denies nothing. Failing closed here would
			// brick every shell call on a machine where the store path is missing.
			if (result.error || result.status !== 2) return;

			return {
				permissionDecision: "deny",
				permissionDecisionReason:
					result.stderr.trim() || "Denied by the sysinit destructive-command guard.",
			};
		},
	},
});
