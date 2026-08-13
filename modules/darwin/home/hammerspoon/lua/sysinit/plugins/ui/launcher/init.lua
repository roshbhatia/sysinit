-- The launcher: one fuzzy list over the applications, the open WezTerm panes, the seshy
-- sessions, the clipboard, and a set of declared commands. It replaces Spotlight on
-- cmd+space, so it has to answer instantly and to index only what is asked for rather than
-- the whole disk.
local json_loader = require("sysinit.pkg.utils.json_loader")
local clipboard = require("sysinit.plugins.ui.launcher.clipboard")
local recency = require("sysinit.plugins.ui.launcher.recency")

local M = {}

-- The applications, cached across opens, because scanning the directories on every open is
-- the cost Spotlight is disliked for. The live sources are cheap enough to ask again.
local apps = nil
local chooser = nil
local config = nil

-- The keys that move the selection, live only while the panel is up. A modal rather than an
-- `hs.eventtap`, so shift+j reaches the query field as a `J` everywhere else.
local keys = nil

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

--- Every `.app` directly under `dir`, and under one level of subdirectory, because the Nix
--- and home-manager apps sit in a folder of their own inside `/Applications` and
--- `~/Applications` and a one-level scan never reaches them.
---@param dir string
---@param into table[]
---@param seen table<string, boolean>
local function scan(dir, into, seen)
  local ok, iter, state = pcall(hs.fs.dir, dir)
  if not ok or not iter then
    return
  end
  local nested = {}
  for name in iter, state do
    if name ~= "." and name ~= ".." then
      local path = dir .. "/" .. name
      if name:sub(-4) == ".app" then
        if not seen[name] then
          seen[name] = true
          into[#into + 1] = {
            text = name:sub(1, #name - 4),
            subText = dir,
            image = hs.image.iconForFile(path),
            kind = "app",
            path = path,
          }
        end
      else
        nested[#nested + 1] = path
      end
    end
  end
  for _, path in ipairs(nested) do
    local attrs = hs.fs.attributes(path)
    if attrs and attrs.mode == "directory" then
      local sub_ok, sub_iter, sub_state = pcall(hs.fs.dir, path)
      if sub_ok and sub_iter then
        for name in sub_iter, sub_state do
          if name:sub(-4) == ".app" and not seen[name] then
            seen[name] = true
            into[#into + 1] = {
              text = name:sub(1, #name - 4),
              subText = path,
              image = hs.image.iconForFile(path .. "/" .. name),
              kind = "app",
              path = path .. "/" .. name,
            }
          end
        end
      end
    end
  end
end

--- Every application worth listing, with its icon.
---@return table[]
local function app_rows()
  if apps ~= nil then
    return apps
  end
  local found, seen = {}, {}
  for _, dir in ipairs(settings().appDirs or {}) do
    scan(dir, found, seen)
  end
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

--- The open Firefox tabs, read by the helper that can decompress the session store.
---@param cb fun(rows: table[])
local function tab_rows(cb)
  local tool = settings().fftabs
  if tool == nil then
    return cb({})
  end
  json({ tool }, function(tabs)
    local rows = {}
    for _, tab in ipairs(tabs) do
      rows[#rows + 1] = {
        text = tab.title or tab.url or "",
        subText = tab.url or "Firefox tab",
        kind = "tab",
        url = tab.url,
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

--- Open one row, and record that it was opened, so the next list puts it near the top.
---@param choice table|nil
local function activate(choice)
  if choice == nil then
    return
  end
  recency.touch(choice)

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
    local wezterm = settings().wezterm
    if wezterm and choice.path then
      -- A window in that session's workspace and directory, which is what opening a
      -- session means. `sy` names the path; wezterm holds the workspace.
      run({ wezterm, "cli", "spawn", "--new-window", "--workspace", choice.text, "--cwd", choice.path })
      hs.application.launchOrFocus("WezTerm")
    end
  elseif choice.kind == "clipboard" then
    clipboard.restore(choice.entry)
  elseif choice.kind == "tab" then
    if choice.url then
      hs.urlevent.openURL(choice.url)
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

--- Move the selection by posting the arrow key the panel already handles, rather than
--- setting the selected row, so the list scrolls and stops at its ends on its own.
---@param key string
local function step(key)
  hs.eventtap.keyStroke({}, key, 0)
end

--- Build the chooser. No colours of its own: `hs.chooser` is an AppKit panel, and left
--- alone it takes the system's own vibrant appearance, which is what makes it read as a
--- native window rather than a themed one.
local function build()
  chooser = hs.chooser.new(activate)
  chooser:rows(10)
  chooser:width(28)
  chooser:searchSubText(true)
  chooser:placeholderText("Search apps, panes, sessions, tabs, clipboard")

  keys = hs.hotkey.modal.new()
  keys:bind(
    { "shift" },
    "j",
    function()
      step("down")
    end,
    nil,
    function()
      step("down")
    end
  )
  keys:bind(
    { "shift" },
    "k",
    function()
      step("up")
    end,
    nil,
    function()
      step("up")
    end
  )
  chooser:showCallback(function()
    keys:enter()
  end)
  chooser:hideCallback(function()
    keys:exit()
  end)

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
  M.gather(function(rows)
    chooser:choices(rows)
  end)
  chooser:query(nil)
  chooser:show()
end

--- Every row, ordered by how recently it was opened, handed over as soon as there is
--- something to show and again as each live source answers. The instant sources go first,
--- so the list is up and typeable before any tool has replied.
---@param cb fun(rows: table[])
function M.gather(cb)
  local rows = {}
  local function fold(found)
    for _, row in ipairs(found) do
      rows[#rows + 1] = row
    end
    cb(recency.sort(rows))
  end

  fold(app_rows())
  fold(command_rows())
  fold(clipboard.rows())
  pane_rows(fold)
  session_rows(fold)
  tab_rows(fold)
end

--- Forget the cached applications and settings, for a caller that has just installed one.
function M.reindex()
  apps = nil
  config = nil
end

function M.setup()
  clipboard.start()

  hs.hotkey.bind({ "cmd" }, "space", function()
    M.toggle()
  end)

  -- The applications are cached, so one installed while Hammerspoon is up would not
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
