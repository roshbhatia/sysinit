local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local nf = wezterm.nerdfonts or {}

local M = {}

M.state_icons = {
  waiting = nf.md_clock_alert or "⏱",
  done = nf.md_check_circle or "✔",
  working = nf.md_loading or "⟳",
  idle = nf.cod_circle_small_filled or "○",
}

M.state_labels = {
  waiting = "Needs Input",
  done = "Done",
  working = "Working",
  idle = "",
}

M.suppressed_reasons = { ["your move"] = true, ["submit"] = true, ["message"] = true }

function M.status_color(status, colors)
  if status == "waiting" then
    return colors.waiting
  elseif status == "done" then
    return colors.done
  elseif status == "working" then
    return colors.working
  end
  return nil
end

function M.status_label(status, reason)
  local lbl = M.state_labels[status] or ""
  local show_reason = reason and reason ~= "" and not M.suppressed_reasons[reason]
  if lbl == "" and not show_reason then
    return ""
  end
  local parts = {}
  if lbl ~= "" then
    parts[#parts + 1] = lbl
  end
  if show_reason then
    parts[#parts + 1] = reason
  end
  return table.concat(parts, " · ")
end

function M.age(secs)
  if not secs or secs < 0 then
    return ""
  end
  if secs < 60 then
    return string.format("%ds", secs)
  elseif secs < 3600 then
    return string.format("%dm", math.floor(secs / 60))
  end
  return string.format("%dh", math.floor(secs / 3600))
end

function M.smart_path(full_cwd)
  if not full_cwd or full_cwd == "" then
    return ""
  end
  local home = os.getenv("HOME") or ""
  local seshy_base = utils.state_path("seshySessions", "seshy/sessions")
  if full_cwd == seshy_base or full_cwd:sub(1, #seshy_base + 1) == seshy_base .. "/" then
    local after = full_cwd:sub(#seshy_base + 2)
    return after ~= "" and ("{sy}/" .. after) or "{sy}"
  end
  local gh_base = home .. "/github/"
  if full_cwd:sub(1, #gh_base) == gh_base then
    local rest = full_cwd:sub(#gh_base + 1)
    local short = rest:match("^[^/]+/[^/]+/(.+)$") or rest
    return "{gh}/" .. short
  end
  if full_cwd == home then
    return "{home}"
  end
  if full_cwd:sub(1, #home + 1) == home .. "/" then
    return "{home}/" .. full_cwd:sub(#home + 2)
  end
  return full_cwd
end

function M.normalize_proc(raw)
  if not raw or raw == "" then
    return raw
  end
  return (raw:gsub("^%.", ""):gsub("%-wrapped$", ""))
end

-- Processes that hold a pane's pty without doing the work in it. wezterm reports
-- the pane's own foreground process, and a multiplexer client is that process,
-- so the shell and the agent running inside are invisible from the pane alone.
-- Every zmx-backed session read as `zmx` and told you nothing about what it was
-- running, while every other pane named its real process.
local passthrough_procs = {
  zmx = true,
  -- `caffeinate -- <cmd>` holds the pty exactly the way a multiplexer client does, so
  -- a pane running an agent under it read `caffeinate` and named the wrapper instead
  -- of the work.
  caffeinate = true,
}

-- Whether a process name is a wrapper rather than the work.
--
-- Exported because three renderers see only a name: the tab title formatter gets a
-- table rather than a Pane and cannot walk the tree, and `tab_label` reads a title
-- wezterm already derived from one of these names. Each of them needs to know the name
-- is worthless even when it cannot find the better one itself.
---@param name string|nil
---@return boolean
function M.is_passthrough(name)
  if type(name) ~= "string" or name == "" then
    return false
  end
  return passthrough_procs[M.normalize_proc(name):lower()] == true
end

-- Deepest descendant of a passthrough process, by pid order at each level.
--
-- Within one wrapper's subtree the highest pid is the newest process, which is
-- what the pane is showing: `zmx attach` re-execs itself before spawning the
-- shell, so the chain is zmx -> zmx -> zsh -> whatever the shell started.
-- The depth cap is a loop guard, not a semantic limit; the real chains are 3
-- deep and a cycle in this tree would otherwise hang the switcher render.
local function deepest_proc_name(info, depth)
  if depth <= 0 or type(info) ~= "table" then
    return nil
  end
  local best_pid, best_child = nil, nil
  for pid, child in pairs(info.children or {}) do
    if type(pid) == "number" and (best_pid == nil or pid > best_pid) then
      best_pid, best_child = pid, child
    end
  end
  if best_child == nil then
    -- A leaf. `name` is a bare command on macOS, but a login shell arrives as
    -- `-zsh`, so strip the leading dash the same way normalize_proc does.
    local name = info.name
    if type(name) ~= "string" or name == "" then
      return nil
    end
    return M.normalize_proc((name:gsub("^%-", "")))
  end
  return deepest_proc_name(best_child, depth - 1)
end

function M.pane_proc(p, agent)
  local ok, proc_name = pcall(function()
    local proc = p:get_foreground_process_name()
    if proc and proc ~= "" then
      return M.normalize_proc((proc:gsub("/+$", "")):match("([^/]+)$") or "")
    end
    return nil
  end)
  if ok and proc_name and proc_name ~= "" and passthrough_procs[proc_name] then
    -- Only descend for a wrapper. For every other pane wezterm already reports
    -- the right process, and walking the tree there would replace a correct
    -- answer with the newest background child.
    local ok_info, inner = pcall(function()
      return deepest_proc_name(p:get_foreground_process_info(), 8)
    end)
    if ok_info and inner and inner ~= "" and not passthrough_procs[inner] then
      return inner
    end
  end
  -- A wrapper name is not an answer. When the descent above found nothing, say what the
  -- agent is instead, and let the caller fall back to the directory rather than print
  -- the name of the thing holding the pty.
  if ok and proc_name and proc_name ~= "" and not passthrough_procs[proc_name] then
    return proc_name
  end
  if agent and agent ~= "" then
    return agent
  end
  -- The pane's own OSC title, and only when it reads like a process name.
  --
  -- An agent sets it to a sentence describing the session, which the tab line above
  -- already shows, so accepting it printed `in ✳ Identify explicit steps to launch FRA
  -- this week` under a tab of that same name. Returning nothing instead drops the
  -- segment: the switcher omits `in …` for an empty title, and a line that says less
  -- says it once.
  local ok2, title = pcall(function()
    return M.normalize_proc(p:get_title() or "")
  end)
  if ok2 and title and title ~= "" and not title:find("%s") and not M.is_passthrough(title) then
    return title
  end
  return ""
end

function M.tab_label(tab, index, active_pane)
  local ok, title = pcall(function()
    return tab:get_title() or ""
  end)
  -- wezterm derives an unset tab title from the pane's own, so a wrapper's name arrives
  -- here as the tab's title and the switcher listed a tab called `zmx`. Rejecting it
  -- here reaches `pane_proc` below, which is the one path that can walk the tree.
  if ok and title and title ~= "" and not M.is_passthrough(title) then
    return title
  end
  if active_pane then
    local proc = M.pane_proc(active_pane, nil)
    if proc ~= "" then
      return proc
    end
  end
  return "tab " .. tostring(index)
end

return M
