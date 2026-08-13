-- The launcher: one fuzzy list over the applications, the open WezTerm panes, the seshy
-- sessions, and a set of declared commands. It replaces Spotlight on cmd+space, so it has
-- to answer instantly and to index only what is asked for rather than the whole disk.
local theme = require("sysinit.pkg.theme")
local json_loader = require("sysinit.pkg.utils.json_loader")

local M = {}

-- Every source's rows, rebuilt when the launcher opens. Apps are cached across opens,
-- because scanning five directories on every keystroke is the cost Spotlight is disliked
-- for; the live sources are cheap enough to ask again each time.
local apps = nil
local chooser = nil
local config = nil

--- The absolute paths and the declared commands, from Nix. Hammerspoon runs with a
--- minimal PATH, so a tool is named by its full path or it is not found at all.
---@return table
local function settings()
  if config == nil then
    config = json_loader.load_json_file(json_loader.get_config_path("launcher_config.json")) or {}
  end
  return config
end

--- Run a command without waiting for it. Not `hs.execute`, so a path holding a space needs
--- no quoting rule, and not `waitUntilExit`, which blocks the one thread Hammerspoon draws
--- on and would freeze the launcher as it opened.
---@param args string[]
---@param cb fun(out: string|nil)|nil
local function run(args, cb)
  local task = hs.task.new(args[1], function(code, out)
    if cb then
      cb(code == 0 and out or nil)
    end
  end, { table.unpack(args, 2) })
  if task == nil then
    if cb then
      cb(nil)
    end
    return
  end
  task:start()
end

--- Decode a tool's JSON answer, or an empty list.
---@param args string[]
---@param cb fun(decoded: table)
local function json(args, cb)
  run(args, function(out)
    if out == nil or out == "" then
      return cb({})
    end
    local ok, decoded = pcall(hs.json.decode, out)
    cb(ok and decoded or {})
  end)
end

--- Every `.app` under the directories worth scanning, with its icon.
---@return table[]
local function app_rows()
  if apps ~= nil then
    return apps
  end
  local dirs = settings().appDirs or {}
  local found, seen = {}, {}
  for _, dir in ipairs(dirs) do
    local ok, iter, state = pcall(hs.fs.dir, dir)
    if ok and iter then
      for name in iter, state do
        if name:sub(-4) == ".app" and not seen[name] then
          seen[name] = true
          local path = dir .. "/" .. name
          found[#found + 1] = {
            text = name:sub(1, #name - 4),
            subText = dir,
            image = hs.image.iconForFile(path),
            kind = "app",
            path = path,
          }
        end
      end
    end
  end
  table.sort(found, function(a, b)
    return a.text < b.text
  end)
  apps = found
  return apps
end

--- The open WezTerm panes, named by workspace and title, because that is how a reader
--- knows which one they meant.
---@param cb fun(rows: table[])
local function pane_rows(cb)
  local wezterm = settings().wezterm
  if wezterm == nil then
    return cb({})
  end
  json({ wezterm, "cli", "list", "--format", "json" }, function(panes)
    local rows = {}
    for _, pane in ipairs(panes) do
      local title = pane.title or ""
      if title == "" then
        title = pane.tab_title or "pane"
      end
      rows[#rows + 1] = {
        text = string.format("%s: %s", pane.workspace or "default", title),
        subText = string.format("WezTerm pane %d", pane.pane_id or 0),
        kind = "pane",
        pane_id = pane.pane_id,
      }
    end
    cb(rows)
  end)
end

--- The seshy sessions, so jumping to one is in the same list as opening an app.
---@param cb fun(rows: table[])
local function session_rows(cb)
  local sy = settings().sy
  if sy == nil then
    return cb({})
  end
  json({ sy, "list", "--json" }, function(sessions)
    local rows = {}
    for _, session in ipairs(sessions) do
      rows[#rows + 1] = {
        text = session.name or "",
        subText = string.format("seshy session, %d repos", session.repoCount or 0),
        kind = "session",
        path = session.path,
      }
    end
    cb(rows)
  end)
end

--- The declared commands, each one a shell line or a URL. Declared in Nix rather than
--- here, so a new command is a configuration change and not a code change.
---@return table[]
local function command_rows()
  local rows = {}
  for _, command in ipairs(settings().commands or {}) do
    rows[#rows + 1] = {
      text = command.label or "",
      subText = command.about or "command",
      kind = "command",
      run = command.run,
      url = command.url,
    }
  end
  return rows
end

--- Open one row.
---@param choice table|nil
local function activate(choice)
  if choice == nil then
    return
  end
  if choice.kind == "app" then
    hs.application.launchOrFocus(choice.path)
  elseif choice.kind == "pane" then
    local wezterm = settings().wezterm
    if wezterm then
      run({ wezterm, "cli", "activate-pane", "--pane-id", tostring(choice.pane_id) })
    end
    -- The pane is focused inside the mux, and this brings the window it lives in forward,
    -- which is the half `activate-pane` does not do.
    hs.application.launchOrFocus("WezTerm")
  elseif choice.kind == "session" then
    local sy = settings().sy
    local wezterm = settings().wezterm
    if wezterm and choice.path then
      -- A window in that session's workspace and directory, which is what opening a
      -- session means. `sy` names the path; wezterm holds the workspace.
      run({
        wezterm,
        "cli",
        "spawn",
        "--new-window",
        "--workspace",
        choice.text,
        "--cwd",
        choice.path,
      })
      hs.application.launchOrFocus("WezTerm")
    elseif sy then
      hs.execute(sy .. " path " .. choice.text)
    end
  elseif choice.kind == "command" then
    if choice.url then
      hs.urlevent.openURL(choice.url)
    elseif choice.run then
      -- Through a login shell, because a declared command is written the way it would be
      -- typed and may name a tool by its bare name.
      hs.execute(choice.run, true)
    end
  end
end

--- Build the chooser, themed like the rest of this config.
local function build()
  chooser = hs.chooser.new(activate)
  local colors = theme.getColors()
  chooser:bgDark(true)
  chooser:fgColor(colors.foreground)
  chooser:subTextColor(colors.foregroundSecondary or colors.foreground)
  chooser:rows(12)
  chooser:width(30)
  chooser:searchSubText(true)
  return chooser
end

--- Show the launcher, or hide it when it is already up, so the same key both opens and
--- closes it.
function M.toggle()
  if chooser == nil then
    build()
  end
  if chooser:isVisible() then
    chooser:hide()
    return
  end
  -- The instant sources first, so the list is up and typeable before either tool has
  -- answered, and the live ones are folded in as they land.
  local rows = {}
  for _, source in ipairs({ app_rows, command_rows }) do
    for _, row in ipairs(source()) do
      rows[#rows + 1] = row
    end
  end
  chooser:choices(rows)
  chooser:query(nil)
  chooser:show()

  local function fold(found)
    for _, row in ipairs(found) do
      rows[#rows + 1] = row
    end
    if chooser:isVisible() then
      chooser:choices(rows)
    end
  end
  pane_rows(fold)
  session_rows(fold)
end

--- Forget the cached applications, for a caller that has just installed one.
function M.reindex()
  apps = nil
  config = nil
end

function M.setup()
  hs.hotkey.bind({ "cmd" }, "space", function()
    M.toggle()
  end)

  -- The applications are cached, so a new one installed while Hammerspoon is up would not
  -- appear. Watching the directories costs nothing and keeps the list honest.
  for _, dir in ipairs(settings().appDirs or {}) do
    local watcher = hs.pathwatcher.new(dir, function()
      apps = nil
    end)
    if watcher then
      watcher:start()
    end
  end
end

return M
