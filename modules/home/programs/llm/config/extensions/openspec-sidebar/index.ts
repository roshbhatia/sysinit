import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const CACHE_TTL_MS = 5_000;
const EXEC_TIMEOUT_MS = 2_000;
const MIN_COLUMNS = 70;
const SIDEBAR_ID = "openspec-sidebar";
const TOOL_LOG_MAX = 10;
const SUBAGENT_TOOL_PATTERN = /^(task|dispatch|agent)/i;
const WRITE_TOOLS = new Set(["write", "edit", "bash", "computer"]);

interface Theme {
  fg(name: string, text: string): string;
  bold(text: string): string;
}

interface Terminal {
  columns: number;
  rows: number;
  write(data: string): void;
}

interface Tui {
  terminal: Terminal;
  doRender?: () => void;
  requestRender?(): void;
}

interface WidgetUi {
  setWidget(id: string, factory: (tui: Tui, theme: Theme) => { dispose(): void; invalidate(): void; render(width: number): string[] }, options: { placement: "belowEditor" }): void;
  notify?(message: string, level: "info" | "warning"): void;
}

interface SessionManager {
  getSessionId?(): string;
  getSessionName?(): string;
}

interface Model {
  id?: string;
  name?: string;
}

interface RuntimeContext {
  cwd?: string;
  hasUI?: boolean;
  ui?: WidgetUi;
  sessionManager?: SessionManager;
  model?: Model;
  getContextUsage?(): { tokens?: number; percent?: number; contextWindow?: number } | undefined;
}

interface OpenSpecArtifact { id: string; status: string; }
interface OpenSpecChange { name: string; artifacts: OpenSpecArtifact[]; completedTasks?: number; totalTasks?: number; }
interface SidebarState { changes: OpenSpecChange[]; unavailable: boolean; }
interface CachedState { state: SidebarState; at: number; }
interface WorkspaceFile { path: string; added: number; removed: number; }
interface WorkspaceData { branch: string | null; aheadCount: number; untrackedCount: number; files: WorkspaceFile[]; }
interface McpServerInfo { name: string; directCount: number; totalCount: number; tokenEstimate: number; connected: boolean; }
interface SubagentEntry { id: string; name: string; status: "running" | "completed" | "failed"; startedAt: number; completedAt?: number; turns: number; toolCount: number; tokens: number; toolLog: string[]; }
interface SessionData {
  title: string | null;
  id: string | null;
  model: string | null;
  contextTokens: number | null;
  contextPercent: number | null;
  contextWindow: number | null;
  tokensIn: number;
  tokensOut: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  turns: number;
  startedAt: number;
  activeTool: { name: string; startedAt: number } | null;
}

let enabled = true;
let sidebarWidth = 40;
let cache: CachedState | undefined;
let workspaceCache: { data: WorkspaceData; at: number } | undefined;

function runtimeContext(ctx: ExtensionContext): RuntimeContext { return ctx as unknown as RuntimeContext; }
function eventRecord(event: unknown): Record<string, unknown> { return typeof event === "object" && event !== null ? event as Record<string, unknown> : {}; }
function isRecord(value: unknown): value is Record<string, unknown> { return typeof value === "object" && value !== null; }
function reset(): string { return "\x1b[22;23;24;39m"; }
function style(theme: Theme, color: string, text: string): string { return theme.fg(color, text) + reset(); }
function dim(theme: Theme, text: string): string { return style(theme, "dim", text); }
function truncate(text: string, width: number): string { return visibleWidth(text) > width ? truncateToWidth(text, width, "", true) : text; }
function panelHeader(theme: Theme, title: string, width: number): string[] { return [theme.bold(` ${title}`), dim(theme, "─".repeat(width))]; }
function formatDuration(ms: number): string { const seconds = Math.floor(ms / 1000); const minutes = Math.floor(seconds / 60); const hours = Math.floor(minutes / 60); return hours > 0 ? `${hours}h${minutes % 60}m` : minutes > 0 ? `${minutes}m${seconds % 60}s` : `${seconds}s`; }
function formatTokens(tokens: number): string { return tokens >= 1_000_000 ? `${(tokens / 1_000_000).toFixed(1)}M` : tokens >= 1_000 ? `${Math.round(tokens / 1_000)}k` : String(tokens); }

function withTimeout<T>(promise: Promise<T>): Promise<T | undefined> { return Promise.race([promise, new Promise<undefined>((resolve) => setTimeout(resolve, EXEC_TIMEOUT_MS))]); }
function parseChangeNames(json: string): string[] | undefined { try { const parsed: unknown = JSON.parse(json); return isRecord(parsed) && Array.isArray(parsed.changes) ? parsed.changes.flatMap((change) => isRecord(change) && typeof change.name === "string" && change.name.length > 0 ? [change.name] : []) : undefined; } catch { return undefined; } }
function parseArtifacts(json: string): OpenSpecArtifact[] { try { const parsed: unknown = JSON.parse(json); return isRecord(parsed) && Array.isArray(parsed.artifacts) ? parsed.artifacts.flatMap((artifact) => isRecord(artifact) && typeof artifact.id === "string" && typeof artifact.status === "string" ? [{ id: artifact.id, status: artifact.status }] : []) : []; } catch { return []; } }
async function taskProgress(cwd: string | undefined, name: string): Promise<Pick<OpenSpecChange, "completedTasks" | "totalTasks">> { if (!cwd) return {}; try { const tasks = await readFile(join(cwd, "openspec", "changes", name, "tasks.md"), "utf8"); const totalTasks = (tasks.match(/^\s*- \[[ xX]\] /gm) ?? []).length; const completedTasks = (tasks.match(/^\s*- \[[xX]\] /gm) ?? []).length; return totalTasks > 0 ? { completedTasks, totalTasks } : {}; } catch { return {}; } }
async function readState(pi: ExtensionAPI, cwd: string | undefined): Promise<SidebarState> { const listed = await withTimeout(pi.exec("openspec", ["list", "--json", "--no-color"])); if (!listed || listed.code !== 0) return { changes: [], unavailable: true }; const names = parseChangeNames(listed.stdout); if (!names) return { changes: [], unavailable: true }; const changes = await Promise.all(names.map(async (name) => { const status = await withTimeout(pi.exec("openspec", ["status", "--change", name, "--json", "--no-color"])); return { name, artifacts: status && status.code === 0 ? parseArtifacts(status.stdout) : [], ...(await taskProgress(cwd, name)) }; })); return { changes, unavailable: false }; }
async function refresh(pi: ExtensionAPI, cwd: string | undefined): Promise<SidebarState> { if (cache && Date.now() - cache.at < CACHE_TTL_MS) return cache.state; const state = await readState(pi, cwd); cache = { state, at: Date.now() }; return state; }

function runGit(cwd: string, args: string[]): string { try { return execFileSync("git", args, { cwd, encoding: "utf8", timeout: EXEC_TIMEOUT_MS, stdio: ["ignore", "pipe", "ignore"] }).trim(); } catch { return ""; } }
function getWorkspace(cwd: string | undefined): WorkspaceData { const empty: WorkspaceData = { branch: null, aheadCount: 0, untrackedCount: 0, files: [] }; if (!cwd) return empty; if (workspaceCache && Date.now() - workspaceCache.at < 2_000) return workspaceCache.data; const branch = runGit(cwd, ["branch", "--show-current"]); if (!branch) return empty; const ahead = Number.parseInt(runGit(cwd, ["rev-list", "@{u}..HEAD", "--count"]), 10) || 0; const status = runGit(cwd, ["status", "--porcelain"]); const files = runGit(cwd, ["diff", "--numstat", "HEAD"]).split("\n").flatMap((line) => { const [added, removed, path] = line.split("\t"); const plus = Number.parseInt(added ?? "", 10); const minus = Number.parseInt(removed ?? "", 10); return Number.isFinite(plus) && Number.isFinite(minus) && path ? [{ path, added: plus, removed: minus }] : []; }).sort((left, right) => right.added + right.removed - left.added - left.removed).slice(0, 15); const data = { branch, aheadCount: ahead, untrackedCount: status.split("\n").filter((line) => line.startsWith("??")).length, files }; workspaceCache = { data, at: Date.now() }; return data; }
function invalidateWorkspace(): void { workspaceCache = undefined; }

function readJson(path: string): unknown { try { return JSON.parse(readFileSync(path, "utf8")); } catch { return undefined; } }
function getMcpServers(): McpServerInfo[] {
  const agentDir = process.env["PI_AGENT_DIR"] ?? join(homedir(), ".pi", "agent");
  const config = readJson(join(agentDir, "mcp.json"));
  const cached = readJson(join(agentDir, "mcp-cache.json"));
  const configured = isRecord(config) && isRecord(config.mcpServers) ? config.mcpServers : {};
  const servers = isRecord(cached) && isRecord(cached.servers) ? cached.servers : {};
  const globalSettings = isRecord(config) && isRecord(config.settings) ? config.settings : {};
  const globalDirect = globalSettings.directTools;
  const names = Object.keys(configured).length > 0 ? Object.keys(configured) : Object.keys(servers);

  return names.map((name) => {
    const definition = isRecord(configured[name]) ? configured[name] : {};
    const server = isRecord(servers[name]) ? servers[name] : {};
    const tools = Array.isArray(server.tools) ? server.tools.filter(isRecord) : [];
    const direct = definition.directTools ?? globalDirect;
    const excluded = Array.isArray(definition.excludeTools)
      ? definition.excludeTools.filter((tool): tool is string => typeof tool === "string")
      : [];
    let directCount = 0;
    let totalCount = 0;
    let tokenEstimate = 0;

    for (const tool of tools) {
      const toolName = typeof tool.name === "string" ? tool.name : "";
      if (!toolName || excluded.includes(toolName)) continue;
      totalCount++;
      const isDirect = direct === true || (Array.isArray(direct) && direct.includes(toolName));
      if (!isDirect) continue;
      directCount++;
      tokenEstimate += Math.ceil((toolName.length + (typeof tool.description === "string" ? tool.description.length : 0) + JSON.stringify(tool.inputSchema ?? {}).length) / 4) + 10;
    }

    return { name, directCount, totalCount, tokenEstimate, connected: tools.length > 0 };
  });
}

function renderSession(session: SessionData, theme: Theme, width: number): string[] { const lines = panelHeader(theme, "Session", width); lines.push(dim(theme, `  ${truncate(session.title ?? "(waiting for first message…)", Math.max(1, width - 2))}`)); if (session.id) lines.push(dim(theme, `  ${session.id}`)); lines.push(""); lines.push(dim(theme, "  model ") + style(theme, session.model ? "accent" : "muted", truncate(session.model ?? "—", Math.max(1, width - 8)))); if (session.contextPercent !== null) lines.push(dim(theme, "  ctx   ") + style(theme, session.contextPercent > 90 ? "warning" : "text", `${formatTokens(session.contextTokens ?? 0)} / ${formatTokens(session.contextWindow ?? 0)} (${session.contextPercent.toFixed(1)}%)`)); else lines.push(dim(theme, "  ctx   —")); if (session.activeTool) lines.push(dim(theme, "  tool  ") + style(theme, "accent", `${truncate(session.activeTool.name, Math.max(1, width - 16))} (${formatDuration(Date.now() - session.activeTool.startedAt)})`)); lines.push(""); const total = session.tokensIn + session.tokensOut + session.cacheRead + session.cacheWrite; lines.push(dim(theme, `  time  ${formatDuration(Date.now() - session.startedAt)}   turns ${session.turns || "—"}`)); lines.push(dim(theme, `  in    ${formatTokens(session.tokensIn)}   out   ${formatTokens(session.tokensOut)}`)); lines.push(dim(theme, `  total ${formatTokens(total)}   cost  ${session.cost > 0 ? `$${session.cost.toFixed(3)}` : "—"}`)); return lines; }
function renderMcp(servers: McpServerInfo[], theme: Theme, width: number): string[] { if (servers.length === 0) return []; const lines = panelHeader(theme, "MCP Servers", width); for (const server of servers) { const glyph = server.connected ? style(theme, server.directCount === server.totalCount && server.totalCount > 0 ? "success" : "warning", "●") : dim(theme, "○"); const suffix = `  ${server.directCount}/${server.totalCount}${server.directCount > 0 ? `  ~${server.tokenEstimate.toLocaleString()}` : ""}`; lines.push(dim(theme, "  ") + glyph + " " + style(theme, "accent", truncate(server.name, Math.max(1, width - suffix.length - 4))) + dim(theme, suffix)); } return lines; }
function renderOpenSpec(state: SidebarState, theme: Theme, width: number): string[] { const lines = panelHeader(theme, "OpenSpec", width); if (state.unavailable) return [...lines, dim(theme, "  unavailable")]; if (state.changes.length === 0) return [...lines, dim(theme, "  no active changes")]; for (const change of state.changes) { lines.push(style(theme, "text", `  ${truncate(change.name, Math.max(1, width - 2))}`)); if (change.totalTasks !== undefined && change.completedTasks !== undefined) lines.push(dim(theme, "    tasks ") + style(theme, change.completedTasks === change.totalTasks ? "success" : "warning", `${change.completedTasks}/${change.totalTasks}`)); for (const artifact of change.artifacts) lines.push(dim(theme, `    ${artifact.id} `) + style(theme, artifact.status === "complete" ? "success" : artifact.status === "blocked" ? "error" : "warning", artifact.status)); } return lines; }
function renderSubagents(subagents: SubagentEntry[], theme: Theme, width: number): string[] { const completed = subagents.filter((agent) => agent.status === "completed").length; const lines = panelHeader(theme, `Async Subagents (${completed}/${subagents.length})`, width); if (subagents.length === 0) return [...lines, dim(theme, "  (no subagents)")]; for (const agent of subagents) { const color = agent.status === "completed" ? "success" : agent.status === "failed" ? "warning" : "accent"; const glyph = agent.status === "completed" ? "✓" : agent.status === "failed" ? "✗" : "●"; lines.push(style(theme, color, glyph) + " " + style(theme, color, truncate(agent.name, Math.max(1, width - 2)))); const elapsed = (agent.completedAt ?? Date.now()) - agent.startedAt; lines.push(dim(theme, `  ${agent.status} (${formatDuration(elapsed)})`)); lines.push(dim(theme, `  ${agent.turns} turns · ${agent.toolCount} tools · ${formatTokens(agent.tokens)} tokens`)); for (const entry of agent.toolLog.slice(-3)) lines.push(dim(theme, `  ${truncate(entry, Math.max(1, width - 2))}`)); } return lines; }
function renderWorkspace(workspace: WorkspaceData, theme: Theme, width: number): string[] { const status = workspace.branch ? `⎇ ${workspace.branch}${workspace.aheadCount > 0 ? ` +${workspace.aheadCount}` : ""}${workspace.untrackedCount > 0 ? ` ?${workspace.untrackedCount}` : ""}` : ""; const lines = [theme.bold(" Workspace") + (status ? dim(theme, ` ${truncate(status, Math.max(1, width - 11))}`) : ""), dim(theme, "─".repeat(width))]; if (!workspace.branch) return [...lines, dim(theme, "  (not a git repo)")]; if (workspace.files.length === 0) return [...lines, dim(theme, "  (clean)")]; for (const file of workspace.files) { const stat = `+${file.added}${file.removed > 0 ? ` -${file.removed}` : ""}`; lines.push(truncate(file.path, Math.max(1, width - stat.length - 1)) + " " + style(theme, "success", stat)); } return lines; }
function renderSidebar(state: SidebarState, session: SessionData, subagents: SubagentEntry[], cwd: string | undefined, theme: Theme, width: number): string[] { return [renderSession(session, theme, width), renderMcp(getMcpServers(), theme, width), renderOpenSpec(state, theme, width), renderSubagents(subagents, theme, width), renderWorkspace(getWorkspace(cwd), theme, width)].filter((panel) => panel.length > 0).flatMap((panel, index) => index === 0 ? panel : ["", ...panel]); }

function descriptorFor(object: object, key: string): PropertyDescriptor | undefined { let target: object | null = object; while (target) { const descriptor = Object.getOwnPropertyDescriptor(target, key); if (descriptor) return descriptor; target = Object.getPrototypeOf(target); } return undefined; }
class SidebarCompositor { private readonly terminal: Terminal; private readonly originalColumns: PropertyDescriptor | undefined; private readonly originalRender: (() => void) | undefined; private disposed = false; constructor(private readonly tui: Tui, private readonly theme: Theme, private readonly lines: () => string[], private readonly width: number) { this.terminal = tui.terminal; this.originalColumns = descriptorFor(this.terminal, "columns"); this.originalRender = tui.doRender; } install(): void { const terminal = this.terminal; const columns = this.originalColumns; const width = this.width; Object.defineProperty(terminal, "columns", { configurable: true, enumerable: true, get() { const raw = columns?.get ? columns.get.call(terminal) : columns?.value; return Math.max(1, (typeof raw === "number" ? raw : 80) - width - 1); } }); if (!this.originalRender) return; this.tui.doRender = () => { this.originalRender?.call(this.tui); this.paint(); }; } paint(): void { if (this.disposed) return; const rawColumns = this.originalColumns?.get ? this.originalColumns.get.call(this.terminal) : this.originalColumns?.value; const columns = typeof rawColumns === "number" ? rawColumns : 80; if (columns < MIN_COLUMNS) return; const separatorColumn = columns - this.width; const sidebarColumn = separatorColumn + 1; const lines = this.lines(); let output = "\x1b[?2026h\x1b7\x1b[?7l"; for (let row = 1; row <= this.terminal.rows; row++) { output += `\x1b[${row};${separatorColumn}H${dim(this.theme, "│")}`; output += `\x1b[${row};${sidebarColumn}H`; output += row <= lines.length ? truncate(lines[row - 1], this.width) : " ".repeat(this.width); } output += "\x1b[?7h\x1b8\x1b[?2026l"; this.terminal.write(output); } dispose(): void { this.disposed = true; if (this.originalColumns) Object.defineProperty(this.terminal, "columns", this.originalColumns); else Reflect.deleteProperty(this.terminal, "columns"); if (this.originalRender) this.tui.doRender = this.originalRender; } }

export default function (pi: ExtensionAPI): void {
  let compositor: SidebarCompositor | undefined;
  let latestState: SidebarState = { changes: [], unavailable: false };
  let currentContext: RuntimeContext | undefined;
  let tui: Tui | undefined;
  let theme: Theme | undefined;
  let requestRender: (() => void) | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;
  const subagents = new Map<string, SubagentEntry>();
  let activeSubagentId: string | undefined;
  let session: SessionData = { title: null, id: null, model: null, contextTokens: null, contextPercent: null, contextWindow: null, tokensIn: 0, tokensOut: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0, startedAt: Date.now(), activeTool: null };
  const lines = (): string[] => theme
    ? renderSidebar(latestState, session, [...subagents.values()], currentContext?.cwd, theme, sidebarWidth)
    : [];
  const installCompositor = (): void => { compositor?.dispose(); compositor = undefined; if (!enabled || !tui || !theme || tui.terminal.columns < MIN_COLUMNS) return; compositor = new SidebarCompositor(tui, theme, lines, sidebarWidth); compositor.install(); };
  const updateUsage = (runtime: RuntimeContext): void => { const usage = runtime.getContextUsage?.(); session.contextTokens = typeof usage?.tokens === "number" ? usage.tokens : null; session.contextPercent = typeof usage?.percent === "number" ? usage.percent : null; session.contextWindow = typeof usage?.contextWindow === "number" ? usage.contextWindow : null; session.model = runtime.model?.name ?? runtime.model?.id ?? null; };
  const update = async (ctx: ExtensionContext): Promise<void> => { currentContext = runtimeContext(ctx); updateUsage(currentContext); latestState = await refresh(pi, currentContext.cwd); compositor?.paint(); };
  const redraw = (): void => { compositor?.paint(); requestRender?.(); };

  pi.on("session_start", async (_event, ctx) => { currentContext = runtimeContext(ctx); const manager = currentContext.sessionManager; session = { title: manager?.getSessionName?.() ?? null, id: manager?.getSessionId?.() ?? null, model: null, contextTokens: null, contextPercent: null, contextWindow: null, tokensIn: 0, tokensOut: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0, startedAt: Date.now(), activeTool: null }; subagents.clear(); activeSubagentId = undefined; updateUsage(currentContext); if (timer) clearInterval(timer); timer = setInterval(redraw, 30_000); if (!currentContext.hasUI || !currentContext.ui) return; await update(ctx); currentContext.ui.setWidget(SIDEBAR_ID, (nextTui, nextTheme) => { tui = nextTui; theme = nextTheme; requestRender = () => nextTui.requestRender?.(); installCompositor(); return { dispose() { compositor?.dispose(); compositor = undefined; tui = undefined; theme = undefined; requestRender = undefined; }, invalidate() {}, render() { return []; } }; }, { placement: "belowEditor" }); });
  pi.on("session_shutdown", async () => { if (timer) clearInterval(timer); timer = undefined; });
  pi.on("before_agent_start", async (event, ctx) => { currentContext = runtimeContext(ctx); const prompt = eventRecord(event).prompt; if (!session.title && typeof prompt === "string") session.title = truncate(prompt.split("\n")[0].trim(), 60); updateUsage(currentContext); redraw(); });
  pi.on("tool_call", async (event, ctx) => { currentContext = runtimeContext(ctx); const details = eventRecord(event); const toolName = typeof details.toolName === "string" ? details.toolName : ""; const toolCallId = typeof details.toolCallId === "string" ? details.toolCallId : toolName; if (SUBAGENT_TOOL_PATTERN.test(toolName)) { const input = eventRecord(details.input); const name = [input.name, input.title, input.description, input.task].find((value): value is string => typeof value === "string") ?? "subagent"; subagents.set(toolCallId, { id: toolCallId, name: name.split("\n")[0].slice(0, 60), status: "running", startedAt: Date.now(), turns: 0, toolCount: 0, tokens: 0, toolLog: [] }); activeSubagentId = toolCallId; } else if (activeSubagentId) { const agent = subagents.get(activeSubagentId); if (agent) { agent.toolLog.push(`${toolName}: ${typeof details.input === "string" ? details.input.slice(0, 40) : ""}`); if (agent.toolLog.length > TOOL_LOG_MAX) agent.toolLog.shift(); agent.toolCount++; } } redraw(); });
  pi.on("tool_result", async (event) => { const details = eventRecord(event); const toolName = typeof details.toolName === "string" ? details.toolName : ""; const toolCallId = typeof details.toolCallId === "string" ? details.toolCallId : toolName; if (WRITE_TOOLS.has(toolName.toLowerCase())) invalidateWorkspace(); const agent = subagents.get(toolCallId); if (agent) { agent.status = details.isError === true ? "failed" : "completed"; agent.completedAt = Date.now(); if (activeSubagentId === toolCallId) activeSubagentId = undefined; } redraw(); });
  pi.on("tool_execution_start", async (event) => { const toolName = eventRecord(event).toolName; session.activeTool = { name: typeof toolName === "string" ? toolName : "tool", startedAt: Date.now() }; redraw(); });
  pi.on("tool_execution_end", async () => { session.activeTool = null; redraw(); });
  pi.on("message_end", async (event) => { const message = eventRecord(event).message; if (!isRecord(message) || message.role !== "assistant" || message.stopReason === "error" || message.stopReason === "aborted") return; const usage = isRecord(message.usage) ? message.usage : {}; const input = typeof usage.input === "number" ? usage.input : 0; const output = typeof usage.output === "number" ? usage.output : 0; const cacheRead = typeof usage.cacheRead === "number" ? usage.cacheRead : 0; const cacheWrite = typeof usage.cacheWrite === "number" ? usage.cacheWrite : 0; const cost = isRecord(usage.cost) && typeof usage.cost.total === "number" ? usage.cost.total : 0; session.tokensIn += input; session.tokensOut += output; session.cacheRead += cacheRead; session.cacheWrite += cacheWrite; session.cost += cost; if (activeSubagentId) { const agent = subagents.get(activeSubagentId); if (agent) { agent.turns++; agent.tokens += input + output; } } redraw(); });
  pi.on("turn_end", async (_event, ctx) => { await update(ctx); invalidateWorkspace(); session.turns++; redraw(); });
  pi.on("agent_end", async (_event, ctx) => { currentContext = runtimeContext(ctx); updateUsage(currentContext); invalidateWorkspace(); redraw(); });
  pi.on("model_select", async (_event, ctx) => { currentContext = runtimeContext(ctx); updateUsage(currentContext); redraw(); });
  pi.registerCommand("openspec-sidebar", { description: "Control OpenSpec sidebar: /openspec-sidebar on | off | width <N>", handler: async (args, ctx) => { const runtime = runtimeContext(ctx); const [command, value] = (args?.trim() ?? "").split(/\s+/, 2); if (command === "width") { const width = Number.parseInt(value ?? "", 10); if (!Number.isInteger(width) || width < 24 || width > 60) { runtime.ui?.notify?.("Usage: /openspec-sidebar width <24-60>", "warning"); return; } sidebarWidth = width; } else if (command === "on" || command === "off") enabled = command === "on"; else { runtime.ui?.notify?.("Usage: /openspec-sidebar on | off | width <N>", "warning"); return; } installCompositor(); redraw(); runtime.ui?.notify?.(`OpenSpec sidebar ${enabled ? "enabled" : "disabled"}`, "info"); } });
}
