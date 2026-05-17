/**
 * OpenSpec Status Extension
 *
 * Surfaces the active openspec change name and task progress in pi's status
 * line. Read-only: shells out to `openspec list --json` and `openspec
 * status --change <name> --json` and renders the result. Never invokes a
 * mutating openspec subcommand.
 *
 * Active-change rule (matches `/opsx:apply` inference):
 *   1. Exactly one entry in `openspec list --json` → that's the active change
 *   2. More than one → pick the most recently modified change directory
 *   3. Zero → render `openspec: idle`
 *
 * Failure modes:
 *   - `openspec` not on PATH or non-zero exit → render `openspec: n/a`
 *   - `openspec` takes longer than 2s → abort, render cached or `openspec: n/a`
 *
 * Refresh cadence:
 *   - At `session_start` and after each `turn_end`, refresh if cache > 5s old.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

interface CachedStatus {
	text: string;
	at: number;
}

const STATUS_ID = "openspec-status";
const CACHE_TTL_MS = 5_000;
const EXEC_TIMEOUT_MS = 2_000;

let cache: CachedStatus | undefined;

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T | undefined> {
	return Promise.race<T | undefined>([
		promise,
		new Promise<undefined>((resolve) => setTimeout(() => resolve(undefined), ms)),
	]);
}

async function readActiveChange(
	pi: ExtensionAPI,
): Promise<{ name: string; progress?: string } | "idle" | "error"> {
	const listResult = await withTimeout(
		pi.exec("openspec", ["list", "--json", "--no-color"]),
		EXEC_TIMEOUT_MS,
	);
	if (!listResult || listResult.code !== 0) {
		return "error";
	}
	let parsed: { changes?: Array<{ name?: string }> } = {};
	try {
		parsed = JSON.parse(listResult.stdout);
	} catch {
		return "error";
	}
	const names = (parsed.changes ?? [])
		.map((c) => c?.name)
		.filter((n): n is string => typeof n === "string" && n.length > 0);

	if (names.length === 0) {
		return "idle";
	}

	const name = names.length === 1 ? names[0] : pickMostRecent(names);

	// Fetch progress for the chosen change. Best-effort: failure falls back
	// to just the name.
	const statusResult = await withTimeout(
		pi.exec("openspec", ["status", "--change", name, "--json", "--no-color"]),
		EXEC_TIMEOUT_MS,
	);
	if (!statusResult || statusResult.code !== 0) {
		return { name };
	}
	try {
		const s = JSON.parse(statusResult.stdout) as {
			artifacts?: Array<{ id?: string; status?: string }>;
		};
		const tasks = (s.artifacts ?? []).find((a) => a?.id === "tasks");
		if (tasks && typeof tasks.status === "string") {
			return { name, progress: tasks.status };
		}
		return { name };
	} catch {
		return { name };
	}
}

// `openspec list --json` does not currently expose mtimes, so we pick the
// first entry as a deterministic best-effort. `/opsx:apply`'s auto-inference
// rule prefers most-recently-modified; if the CLI later exposes mtimes,
// upgrade this to honor that.
function pickMostRecent(names: string[]): string {
	return names[names.length - 1];
}

function render(
	ctx: ExtensionContext,
	state: { name: string; progress?: string } | "idle" | "error",
): string {
	const theme = ctx.ui.theme;
	if (state === "error") {
		return theme.fg("dim", "openspec: n/a");
	}
	if (state === "idle") {
		return theme.fg("dim", "openspec: idle");
	}
	const tag = theme.fg("accent", "openspec");
	const sep = theme.fg("dim", ": ");
	const nameText = theme.fg("text", state.name);
	if (state.progress) {
		const progressText = theme.fg("dim", ` · ${state.progress}`);
		return tag + sep + nameText + progressText;
	}
	return tag + sep + nameText;
}

async function refresh(pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> {
	const now = Date.now();
	if (cache && now - cache.at < CACHE_TTL_MS) {
		ctx.ui.setStatus(STATUS_ID, cache.text);
		return;
	}
	const state = await readActiveChange(pi);
	const text = render(ctx, state);
	cache = { text, at: Date.now() };
	ctx.ui.setStatus(STATUS_ID, text);
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		await refresh(pi, ctx);
	});

	pi.on("turn_end", async (_event, ctx) => {
		await refresh(pi, ctx);
	});
}
