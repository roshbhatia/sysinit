local M = {}

---@alias HarnessFinding { level: "ok"|"warn"|"error", text: string }

---@return string
local function plugin_state(module, lazy_name)
  if package.loaded[module] then
    return "loaded"
  end
  local ok, config = pcall(require, "lazy.core.config")
  if ok and config.plugins and config.plugins[lazy_name] then
    return "installed, loads on demand"
  end
  return "absent"
end

---@return HarnessFinding[]
function M.findings()
  local out = {}
  local function add(level, text)
    out[#out + 1] = { level = level, text = text }
  end

  local gitrepo = require("utils.gitrepo")
  local repos = gitrepo.status()

  add("ok", "workspace: " .. tostring(repos.workspace))

  local declared = vim.env.SYSINIT_WORKSPACE
  if declared == nil or declared == "" then
    add("ok", "workspace source: inferred, from the git top level or the cwd. `$SYSINIT_WORKSPACE` is unset")
  elseif vim.fs.normalize(vim.fn.expand(declared)) == repos.workspace then
    add("ok", "workspace source: declared by `$SYSINIT_WORKSPACE`")
  else
    add(
      "warn",
      string.format(
        "workspace source: `$SYSINIT_WORKSPACE` is %s, which does not contain the cwd, so the inferred boundary is in use",
        declared
      )
    )
  end

  if repos.source == "none" then
    add(
      "warn",
      "repository query: none has run yet, so no source has answered. Open a diff, or run `:lua require('utils.gitrepo').workspace_roots(function() end)`"
    )
  else
    add(
      "ok",
      string.format(
        "repository query: answered by %s, %d repositor%s found",
        repos.source,
        #repos.roots,
        #repos.roots == 1 and "y" or "ies"
      )
    )
    if #repos.roots == 0 then
      add("warn", "no repository under the workspace, so every review entry point will say so and open nothing")
    end
  end

  if repos.agent then
    add("ok", "`utils` is on PATH")
  else
    add("error", "`utils` is not on PATH, so no repository, change, or note can be read")
  end

  local ok_events, events = pcall(require, "harness.edit_events")
  if not ok_events then
    add("error", "the edit-event watcher module did not load")
  else
    local watch = events.status()
    if watch.active then
      add("ok", "edit-event watcher: running, and it reloads the buffer an agent wrote")
    else
      add("warn", "edit-event watcher: not running")
    end
    if watch.log then
      add("ok", "edit-event log: " .. watch.log .. string.format(" (read to byte %d)", watch.offset))
    else
      add("warn", "edit-event log: not resolved. `utils edit-event --print-log` did not answer, so no event can arrive")
    end
    add("ok", string.format("agent edits recorded this session: %d", watch.touched))
  end

  local ok_deltas, deltas = pcall(require, "harness.deltas")
  if not ok_deltas then
    add("error", "the delta module did not load, so no line can name the prompt that wrote it")
  else
    local delta = deltas.status()
    if delta.dir then
      add("ok", string.format("delta store: %s (%d deltas)", delta.dir, delta.deltas))
    else
      add("warn", "delta store: absent. No agent has written here yet, or `utils edit-event` did not answer")
    end
  end

  local ok_notes, notes = pcall(require, "harness.notes")
  if not ok_notes then
    add("error", "the note module did not load, so a review shows the diff and none of the reasoning")
  elseif vim.fn.executable(notes.tool) ~= 1 then
    add(
      "warn",
      string.format("notes: `%s` is not on PATH, so a file draws no notes and does not fail either", notes.tool)
    )
  else
    add("ok", string.format("notes: %d loaded for this project", notes.count()))
  end

  for _, plugin in ipairs({
    { module = "claudecode", lazy = "claudecode.nvim", need = "an agent's own inline edit" },
    { module = "diffview", lazy = "diffview.nvim", need = "the diff itself" },
  }) do
    local state = plugin_state(plugin.module, plugin.lazy)
    add(state == "absent" and "error" or "ok", string.format("%s: %s (%s)", plugin.lazy, state, plugin.need))
  end

  return out
end

function M.check()
  vim.health.start("harness: the diff review surface")
  for _, finding in ipairs(M.findings()) do
    vim.health[finding.level](finding.text)
  end
end

return M
