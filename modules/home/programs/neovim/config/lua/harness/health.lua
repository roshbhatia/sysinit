-- One report of what the diff review surface can see: which layer answered the
-- repository query, which repositories it found, whether the edit-event watcher is
-- running, the log it resolved, how many events it read, and whether each plugin the
-- review needs is loaded.
local M = {}

--- One finding: `level` is a `vim.health` function name, `text` is the whole line.
---@alias HarnessFinding { level: "ok"|"warn"|"error", text: string }

--- Whether a plugin is loaded, installed but not yet loaded, or absent.
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

  -- Which rule produced that directory, because the wrong workspace is the failure
  -- that looks like every other one: the roots are wrong, so the review is wrong, and
  -- the path alone does not say whether it was declared or inferred.
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

  -- Which tiers are available decides what the next query can use, which is why
  -- both are reported even when the last query succeeded.
  if repos.agent then
    add("ok", "`utils` is on PATH")
  else
    add("warn", "`utils` is not on PATH, so the repository query falls back to the `fd` scan")
  end
  if not repos.fd then
    add(
      "warn",
      "`fd` is not on PATH, so with `utils` absent the query falls back to `git rev-parse`, which sees one repository"
    )
  end

  local ok_events, events = pcall(require, "harness.edit_events")
  if not ok_events then
    add("error", "the edit-event watcher module did not load")
  else
    local watch = events.status()
    if watch.active then
      add("ok", "edit-event watcher: running, with no consumer since the scoped review was removed")
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

  local ok_notes, notes = pcall(require, "harness.notes")
  if not ok_notes then
    add("error", "the agent-note module did not load, so a review shows the diff and none of the reasoning")
  elseif vim.fn.executable(notes.tool) ~= 1 then
    add(
      "warn",
      string.format("agent notes: `%s` is not on PATH, so a review draws no notes and does not fail either", notes.tool)
    )
  else
    add("ok", string.format("agent notes: %d drawn for the open review", notes.count()))
  end

  for _, plugin in ipairs({
    { module = "codediff", lazy = "codediff.nvim", need = "the diff itself" },
    { module = "claudecode", lazy = "claudecode.nvim", need = "an agent's own inline edit" },
  }) do
    local state = plugin_state(plugin.module, plugin.lazy)
    add(state == "absent" and "error" or "ok", string.format("%s: %s (%s)", plugin.lazy, state, plugin.need))
  end

  -- Where this config reaches into codediff's internals. Reported by name because an
  -- upstream rename breaks it silently. Only checked for a module already loaded, so
  -- reading the report does not load a lazy plugin and change what the next line says.
  for _, seam in ipairs({
    {
      module = "codediff.ui.view",
      what = "codediff seam `ui.view.create`",
      cost = "a clean repository reports itself in a message instead of opening `Changes (0)`",
      ok = function(m)
        local ok_path, path = pcall(require, "codediff.core.path")
        return type(m.create) == "function" and ok_path and type(path.empty) == "function"
      end,
    },
  }) do
    local loaded = package.loaded[seam.module]
    if loaded == nil then
      add("ok", string.format("%s: not checked, %s is not loaded yet", seam.what, seam.module))
    elseif seam.ok(loaded) then
      add("ok", seam.what .. ": present")
    else
      add("error", string.format("%s: gone. %s", seam.what, seam.cost))
    end
  end

  return out
end

--- `:checkhealth harness`.
function M.check()
  vim.health.start("harness: the diff review surface")
  for _, finding in ipairs(M.findings()) do
    vim.health[finding.level](finding.text)
  end
end

--- The same findings as one notification, for reading without leaving the diff.
function M.show()
  local lines = {}
  for _, finding in ipairs(M.findings()) do
    lines[#lines + 1] = string.format("%-5s %s", finding.level, finding.text)
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Harness health" })
end

return M
