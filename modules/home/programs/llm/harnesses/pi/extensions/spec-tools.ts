/**
 * The openspec write path, from inside pi.
 *
 * The sidebar already reports the active change, its task counts, and artifact
 * status. Acting on any of it meant leaving the session for `specutil` and
 * `openspec`, so the read path was first-class and the write path was not.
 *
 * Three commands, each a thin front to a tool that already exists. None of them
 * reimplements a gate: `/preflight` runs spec-preflight, `/cite` runs citelock,
 * `/next` runs specutil. A gate reimplemented in an extension is a second copy
 * that drifts from the first.
 *
 * Results are delivered as a follow-up user message rather than a notification.
 * A notification is read by the owner and forgotten; a follow-up puts the output
 * in the transcript where the model can act on it, which is the point of having
 * the write path in the session at all.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

interface RuntimeContext {
	cwd?: string;
	ui?: { notify?(message: string, level: "info" | "warning"): void };
}

const runtime = (ctx: ExtensionContext): RuntimeContext => ctx as unknown as RuntimeContext;

// `pi.exec` takes no cwd, so anything that must run in the session's repository is
// routed through `sh -c` with an explicit cd.
async function run(pi: ExtensionAPI, cwd: string, command: string): Promise<string> {
	const result = await pi.exec("sh", ["-c", `cd ${JSON.stringify(cwd)} && ${command}`]);
	const out = [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
	return out || "(no output)";
}

// The active change is whichever directory under openspec/changes/ was touched
async function activeChange(pi: ExtensionAPI, cwd: string): Promise<string | null> {
	const out = await run(
		pi,
		cwd,
		"ls -dt openspec/changes/*/ 2>/dev/null | grep -v '/archive/' | head -1 | xargs -r basename",
	);
	const name = out.trim();
	return name && name !== "(no output)" ? name : null;
}

async function deliver(pi: ExtensionAPI, title: string, body: string): Promise<void> {
	await pi.sendUserMessage(`${title}\n\n\`\`\`\n${body}\n\`\`\``, { deliverAs: "followUp" });
}

export default function (pi: ExtensionAPI): void {
	pi.registerCommand("next", {
		description: "Runnable subtasks for the active openspec change",
		handler: async (args, ctx) => {
			const rt = runtime(ctx);
			const cwd = rt.cwd;
			if (!cwd) return;
			const change = args?.trim() || (await activeChange(pi, cwd));
			if (!change) {
				rt.ui?.notify?.("No active openspec change", "warning");
				return;
			}
			await deliver(pi, `specutil next: ${change}`, await run(pi, cwd, `specutil next --change ${change}`));
		},
	});

	pi.registerCommand("preflight", {
		description: "Run the deterministic spec-driven authoring rules",
		handler: async (args, ctx) => {
			const rt = runtime(ctx);
			const cwd = rt.cwd;
			if (!cwd) return;
			const stage = args?.trim() || "all";
			await deliver(pi, `spec-preflight: ${stage}`, await run(pi, cwd, `spec-preflight ${stage}`));
		},
	});

	pi.registerCommand("cite", {
		description: "citelock capture <url> --id <id> --quote <text> --class <class>",
		handler: async (args, ctx) => {
			const rt = runtime(ctx);
			const cwd = rt.cwd;
			if (!cwd) return;
			const rest = args?.trim();
			if (!rest) {
				rt.ui?.notify?.(
					"Usage: /cite <url> --id <id> --quote <text> --class <class>",
					"warning",
				);
				return;
			}
			await deliver(pi, `citelock capture ${rest}`, await run(pi, cwd, `citelock capture ${rest}`));
		},
	});
}
