local wezterm = require("wezterm")
local utils = require("sysinit.pkg.utils")

local nf = wezterm.nerdfonts or {}

local M = {}

M.state_icons = {
  waiting = nf.md_clock_alert or "⏱",
  done    = nf.md_check_circle or "✔",
  working = nf.md_loading or "⟳",
  idle    = nf.cod_circle_small_filled or "○",
}

M.state_labels = {
  waiting = "Needs Input",
  done    = "Done",
  working = "Working",
  idle    = "",
}

-- Reasons the agent emits that add nothing next to the label.
M.suppressed_reasons = { ["your move"] = true, ["submit"] = true, ["message"] = true }

function M.status_color(status, colors)
  if status == "waiting" then return colors.waiting
  elseif status == "done" then return colors.done
  elseif status == "working" then return colors.working
  end
  return nil
end

function M.status_label(status, reason)
  local lbl = M.state_labels[status] or ""
  local show_reason = reason and reason ~= "" and not M.suppressed_reasons[reason]
  if lbl == "" and not show_reason then return "" end
  local parts = {}
  if lbl ~= "" then parts[#parts + 1] = lbl end
  if show_reason then parts[#parts + 1] = reason end
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
  if not full_cwd or full_cwd == "" then return "" end
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
  if full_cwd == home then return "{home}" end
  if full_cwd:sub(1, #home + 1) == home .. "/" then
    return "{home}/" .. full_cwd:sub(#home + 2)
  end
  return full_cwd
end

function M.normalize_proc(raw)
  if not raw or raw == "" then return raw end
  return (raw:gsub("^%.", ""):gsub("%-wrapped$", ""))
end

function M.pane_proc(p, agent)
  local ok, proc_name = pcall(function()
    local proc = p:get_foreground_process_name()
    if proc and proc ~= "" then
      return M.normalize_proc((proc:gsub("/+$", "")):match("([^/]+)$") or "")
    end
    return nil
  end)
  if ok and proc_name and proc_name ~= "" then
    return proc_name
  end
  if agent and agent ~= "" then
    return agent
  end
  local ok2, title = pcall(function() return M.normalize_proc(p:get_title() or "") end)
  return (ok2 and title) or ""
end

function M.tab_label(tab, index, active_pane)
  local ok, title = pcall(function()
    return tab:get_title() or ""
  end)
  if ok and title and title ~= "" then
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
