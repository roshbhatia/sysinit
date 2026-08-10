/**
 * Diff Review Extension
 *
 * Opens the working-tree diff in `review`, in a terminal split beside pi. `ctrl+b`,
 * or `/review`.
 *
 * The split is native: the WezTerm CLI under WezTerm, `tmux split-window` under
 * tmux. Without either multiplexer there is no pane to open, so the command is
 * reported instead of being launched into pi's own terminal, which the TUI owns.
 *
 * ctrl+b shadows pi's `tui.editor.cursorLeft`, which is also bound to `left`. That
 * is the owner's choice; `left` still moves the cursor.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

interface Ui {
	notify?(message: string, level?: "info" | "warning" | "error"): void;
}

interface RuntimeContext {
	cwd?: string;
	ui?: Ui;
}

const SPLIT_PERCENT = "45";

// `review` is the whole working-tree changeset in one view.
const VIEWER_COMMAND = ["review"];

// Notes go to `sysinit-agent note`, which writes one record per repository and
const ANNOTATE_PROMPT = [
	"A `review` of the working tree is now open beside this session.",
	"Annotate it with `sysinit-agent note`: read the diff, then leave the notes in one",
	"`sysinit-agent note apply --stdin` batch, whose payload is",
	'`{"notes":[{"file":"<repo-relative path>","line":<n>,"summary":"...","rationale":"...","author":"pi"}]}`',
	"where `line` is 1-based on the MODIFIED side of the diff, never the original side.",
	"Comment on intent, risk, and anything I would not spot myself.",
	"Do not annotate every hunk, and do not edit any file.",
].join(" ");

function runtimeContext(ctx: ExtensionContext): RuntimeContext {
	return ctx as unknown as RuntimeContext;
}

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" = "info"): void {
	runtimeContext(ctx).ui?.notify?.(message, level);
}

function splitCommand(command: string[], cwd: string): string[] | undefined {
	if (process.env["WEZTERM_PANE"]) {
		return ["wezterm", "cli", "split-pane", "--right", "--percent", SPLIT_PERCENT, "--cwd", cwd, "--", ...command];
	}
	if (process.env["TMUX"]) {
		return ["tmux", "split-window", "-h", "-c", cwd, ...command];
	}
	return undefined;
}

type TreeState = "no-repo" | "clean" | "dirty";

// `pi.exec` takes no cwd, so a command that must run in the session's repository
async function treeState(pi: ExtensionAPI, cwd: string): Promise<TreeState> {
	const inRepo = await pi.exec("git", ["-C", cwd, "rev-parse", "--git-dir"]);
	if (inRepo.code !== 0) return "no-repo";
	const hasHead = await pi.exec("git", ["-C", cwd, "rev-parse", "--verify", "HEAD"]);
	if (hasHead.code !== 0) {
		const staged = await pi.exec("git", ["-C", cwd, "diff", "--cached", "--name-only"]);
		return staged.code === 0 && staged.stdout.trim().length > 0 ? "dirty" : "clean";
	}
	const tracked = await pi.exec("git", ["-C", cwd, "diff", "HEAD", "--name-only"]);
	return tracked.code === 0 && tracked.stdout.trim().length > 0 ? "dirty" : "clean";
}

async function open(pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> {
	const cwd = runtimeContext(ctx).cwd;
	if (!cwd) {
		notify(ctx, "diff review: no working directory", "warning");
		return;
	}
	const state = await treeState(pi, cwd);
	if (state === "no-repo") {
		notify(ctx, "diff review: not a git repository", "warning");
		return;
	}
	if (state === "clean") {
		notify(ctx, "diff review: no tracked changes to review", "warning");
		return;
	}

	const split = splitCommand(VIEWER_COMMAND, cwd);
	if (!split) {
		notify(ctx, `diff review: no WezTerm or tmux pane. Run: ${VIEWER_COMMAND.join(" ")}`, "warning");
		return;
	}

	const result = await pi.exec(split[0], split.slice(1));
	if (result.code !== 0) {
		notify(ctx, `diff review: split failed, ${result.stderr.trim() || `exit ${result.code}`}`, "warning");
		return;
	}
	notify(ctx, "diff review: opened in review. Re-run `review` to read the notes.");

	await pi.sendUserMessage(ANNOTATE_PROMPT, { deliverAs: "followUp" });
}

export default function (pi: ExtensionAPI): void {
	pi.registerShortcut("ctrl+b", {
		description: "Review the working-tree diff",
		handler: (ctx) => open(pi, ctx),
	});
	pi.registerCommand("review", {
		description: "Review the working-tree diff in a split",
		handler: (_args, ctx) => open(pi, ctx),
	});
}
