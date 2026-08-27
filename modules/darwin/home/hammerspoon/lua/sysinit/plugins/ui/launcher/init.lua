local ansi = require("sysinit.plugins.ui.launcher.ansi")
local json_loader = require("sysinit.pkg.utils.json_loader")
local clipboard = require("sysinit.plugins.ui.launcher.clipboard")
local emoji = require("sysinit.plugins.ui.launcher.emoji")
local files = require("sysinit.plugins.ui.launcher.files")
local fzf = require("sysinit.plugins.ui.launcher.fzf")
local panel = require("sysinit.plugins.ui.launcher.panel")
local recency = require("sysinit.plugins.ui.launcher.recency")
local settings_panes = require("sysinit.plugins.ui.launcher.settings")
local screenshots = require("sysinit.plugins.ui.screenshots")

local M = {}

-- How often the sources that change on their own are re-read. Panes and
-- sessions are polled; Firefox tabs, apps, and files also have slower paths.
local live_secs = 8
-- Fallback for Firefox events missed during a Hammerspoon reload.
local tabs_secs = 60
local files_secs = 300
-- The app list is watched, and also rescanned on this cadence. FSEvents on
-- /Applications is not something to rely on alone: the watcher misses a drag
-- landed while Hammerspoon was reloading, and a Nix Apps or Home Manager Apps
-- directory is a symlink whose target changes without an event on the path
-- watched. A rescan re-reads directory entries only, because every icon is
-- already cached by path, so it costs a few milliseconds.
local apps_secs = 45
-- How long after a watcher event the rescan runs. Installing an app writes
-- hundreds of files inside the bundle, and each write is an event; one rescan is
-- wanted, after the writes stop.
local settle_apps = 2
local settle_tabs = 1

-- Showing the panel makes its window key, and that activation is a wait on the
-- window server. Measured on this machine it usually costs under 100ms but
-- intermittently blocks for up to 4.9 seconds while the window server is busy,
-- with Hammerspoon burning no CPU. The hotkey cannot fire during that wait, so
-- the presses queue and then all run at once, and the panel flickers through one
-- activation per press. A press inside this window is dropped instead: the first
-- press always acts, and a queued burst arrives inside 5ms so only its first
-- press survives. Deliberate presses are further apart than this.
local settle_secs = 0.12

local apps = nil
local config = nil
-- Held at module scope: a path watcher only Lua-local is garbage collected and
-- silently stops firing, which is why a newly dragged app never appeared.
local watchers = {}
local pending = nil
local tabs_pending = nil
-- Drawing an app's icon and encoding it costs a millisecond or two, and a
-- rescan re-reads every directory to find the one app that changed. Both are
-- keyed by path, so a rescan pays only for what is new.
local drawn = {}
local by_name = nil

-- Every source keeps its rows here, and the base list is composed from whatever
-- is present. Nothing is gathered when the hotkey is pressed.
local held = {
  apps = {},
  commands = {},
  entries = {},
  panes = {},
  prefs = {},
  sessions = {},
  tabs = {},
}

local order = { "apps", "commands", "entries", "panes", "prefs", "sessions", "tabs" }

---@return table
local function settings()
  if config == nil then
    local loaded = json_loader.load_json_file(json_loader.get_config_path("launcher_config.json"))
    config = type(loaded) == "table" and loaded or {}
  end
  return config
end

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

---@param path string
---@return string|nil
local function icon(path)
  local held = drawn[path]
  if held ~= nil then
    return held or nil
  end
  local encoded = nil
  local image = hs.image.iconForFile(path)
  if image ~= nil then
    local ok, made = pcall(function()
      return image:setSize({ w = 24, h = 24 }):encodeAsURLString()
    end)
    encoded = ok and made or nil
  end
  -- `false` rather than nil, so an app whose icon cannot be read is not tried
  -- again on every rescan.
  drawn[path] = encoded or false
  return encoded
end

---@param path string
---@param name string
---@param into table[]
---@param seen table<string, boolean>
local function add_app(path, name, into, seen)
  if seen[name] then
    return
  end
  seen[name] = true
  into[#into + 1] = {
    text = name:sub(1, #name - 4),
    detail = "",
    label = "Application",
    icon = icon(path),
    kind = "app",
    path = path,
  }
end

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
        add_app(path, name, into, seen)
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
          if name:sub(-4) == ".app" then
            add_app(path .. "/" .. name, name, into, seen)
          end
        end
      end
    end
  end
end

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

-- Looked up once per pane, session and tab, and those are rebuilt every few
-- seconds, so the apps are indexed by name rather than scanned each time.
---@param name string
---@return string|nil
local function app_icon(name)
  if by_name == nil then
    by_name = {}
    for _, row in ipairs(app_rows()) do
      by_name[row.text] = row.icon
    end
  end
  return by_name[name]
end

---@param cb fun(rows: table[])
local function pane_rows(cb)
  local wezterm = settings().wezterm
  if wezterm == nil then
    return cb({})
  end
  json({ wezterm, "cli", "--no-auto-start", "list", "--format", "json" }, function(panes)
    local rows = {}
    for _, pane in ipairs(panes) do
      local title = pane.title or ""
      if title == "" then
        title = pane.tab_title or "pane"
      end
      rows[#rows + 1] = {
        text = string.format("%s: %s", pane.workspace or "default", title),
        detail = pane.cwd or "",
        label = "WezTerm Pane",
        icon = app_icon("WezTerm"),
        kind = "pane",
        pane_id = pane.pane_id,
      }
    end
    cb(rows)
  end)
end

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
        detail = string.format("%d repos", session.repoCount or 0),
        label = "Session",
        icon = app_icon("WezTerm"),
        kind = "session",
        path = session.path,
      }
    end
    cb(rows)
  end)
end

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
        detail = tab.url or "",
        label = "Firefox Tab",
        icon = app_icon("Firefox"),
        kind = "tab",
        url = tab.url,
      }
    end
    cb(rows)
  end)
end

-- The sleep kinds an assertion holds off, which together are what `caffeinate
-- -di` holds off. `displayIdle` alone is what the status reads, because the two
-- are only ever set together.
local awake = { "displayIdle", "systemIdle" }

---@return boolean
local function caffeinated()
  return hs.caffeinate.get("displayIdle") == true
end

---@param on boolean
local function caffeinate(on)
  for _, kind in ipairs(awake) do
    hs.caffeinate.set(kind, on, true)
  end
end

---@return table[]
local function command_rows()
  local on = caffeinated()
  local rows = {
    {
      text = "Toggle Caffeinate",
      detail = on and "Currently on; let the display and system sleep"
        or "Currently off; hold off display and system sleep",
      label = "Command",
      glyph = "awake",
      kind = "caffeinate",
      on = not on,
    },
  }
  for _, command in ipairs(settings().commands or {}) do
    rows[#rows + 1] = {
      text = command.label or "",
      detail = "",
      label = "Command",
      glyph = "command",
      kind = "command",
      run = command.run,
      url = command.url,
    }
  end
  return rows
end

-- The two rows that open a list of their own rather than doing something.
---@return table[]
local function entry_rows()
  local rows = {}
  local depth = clipboard.depth()
  if depth > 0 then
    rows[#rows + 1] = {
      text = "Clipboard History",
      detail = string.format("%d held", depth),
      label = "Clipboard",
      glyph = "clipboard",
      kind = "clipboard",
    }
  end
  local count = files.count()
  if count > 0 then
    rows[#rows + 1] = {
      text = "File Search",
      detail = string.format("%d paths", count),
      label = "Files",
      glyph = "folder",
      kind = "files",
    }
  end
  return rows
end

---@param text string
---@return string
local function language(text)
  local head = text:sub(1, 400)
  if head:match("^%s*[{%[]") then
    return "json"
  end
  if head:match("^diff %-%-git") or head:match("\ndiff %-%-git") then
    return "diff"
  end
  if head:match("^#!") or head:match("^%s*[%w%-_/]+%s+%-%-?%w") or head:match("|") then
    return "bash"
  end
  if head:match("^https?://") then
    return "log"
  end
  return "txt"
end

---@param row table
---@param cb fun(html: string)
local function preview(row, cb)
  local text = row.entry and row.entry.text or ""
  local tool = settings().bat
  if tool == nil then
    return cb("<span></span>")
  end
  local task = hs.task.new(tool, function(_, out)
    cb(ansi.html(out or ""))
  end, {
    "--color=always",
    "--paging=never",
    "--style=numbers",
    "--wrap=character",
    "--terminal-width=64",
    "--line-range=:200",
    "--language=" .. language(text),
  })
  if task == nil then
    return cb("<span></span>")
  end
  task:setInput(text)
  task:start()
end

---@return table
local function history()
  return {
    name = "clipboard",
    rows = clipboard.rows(),
    placeholder = "Search the clipboard history",
    verb = "Copy",
    preview = preview,
    hints = { { "&#8629;", "Copy" }, { "esc", "Back" } },
    choose = function(row)
      panel.hide()
      clipboard.restore(row.entry)
    end,
  }
end

---@return table
local function search()
  return {
    name = "files",
    -- The walk writes this list's fzf index itself, and a match comes back with
    -- the line it matched, so a row is built only for the few the panel draws
    -- and nothing holds the tree in between.
    indexed = true,
    head = files.head,
    row = files.row,
    placeholder = "Search files and folders by path",
    verb = "Open",
    hints = {
      { "&#8629;", "Open" },
      { "&#8679;&#8629;", "Reveal" },
      { "&#8984;C", "Copy path" },
      { "esc", "Back" },
    },
    choose = function(row, mods)
      if mods.cmd then
        files.copy(row.path)
        panel.hide()
        return
      end
      panel.hide()
      if mods.shift then
        files.reveal(row.path)
      else
        files.open(row.path)
      end
    end,
  }
end

-- Declared here because toggling caffeinate rebuilds the base list, and the list
-- is composed further down.
local compose

-- Runs a `!` command in a WezTerm window of its own. The shell is re-exec'd
-- after the command so the window stays with its output rather than closing on
-- the last line of it.
---@param command string
local function terminal(command)
  local wezterm = settings().wezterm
  local shell = settings().shell
  if wezterm == nil or shell == nil then
    return
  end
  local args = { wezterm, "start", "--cwd", os.getenv("HOME") }
  if command ~= "" then
    recency.touch({ kind = "shell", text = command })
    compose()
    args[#args + 1] = "--"
    args[#args + 1] = shell
    args[#args + 1] = "-lc"
    args[#args + 1] = command .. "\nexec " .. string.format("%q", shell) .. " -l"
  end
  run(args)
end

local function browser_focus()
  local name = settings().browser or "Firefox"
  hs.application.launchOrFocus(name)
end

---@param value string
local function browser_open(value)
  local url = value:match("^%s*(.-)%s*$") or ""
  if url == "" then
    return
  end
  if not url:match("^[%a][%w+.-]*://") then
    url = "https://" .. url
  end
  hs.urlevent.openURL(url)
end

---@param value string
local function browser_search(value)
  local query = value:match("^%s*(.-)%s*$") or ""
  if query == "" then
    return
  end
  local template = settings().searchURL or "https://www.google.com/search?q=%s"
  local url = template:gsub("%%s", function()
    return hs.http.encodeForQuery(query)
  end, 1)
  hs.urlevent.openURL(url)
end

local actions = {
  {
    name = "terminal",
    label = "Terminal",
    detail = "Open WezTerm or run a shell command",
    glyph = "terminal",
    commands = {
      {
        name = "open",
        detail = "Open a WezTerm window",
        run = function(_)
          panel.hide()
          terminal("")
        end,
      },
      {
        name = "run",
        argument = "command",
        detail = "Run a shell command in a new WezTerm window",
        run = function(arg)
          panel.hide()
          terminal(arg)
        end,
      },
    },
  },
  {
    name = "browser",
    label = "Browser",
    detail = "Focus the browser, open a URL, or search the web",
    glyph = "browser",
    commands = {
      {
        name = "focus",
        detail = "Focus the configured browser",
        run = function(_)
          panel.hide()
          browser_focus()
        end,
      },
      {
        name = "open",
        argument = "url",
        detail = "Open a URL",
        run = function(arg)
          panel.hide()
          browser_open(arg)
        end,
      },
      {
        name = "search",
        argument = "query",
        detail = "Search the web",
        run = function(arg)
          panel.hide()
          browser_search(arg)
        end,
      },
    },
  },
  {
    name = "files",
    label = "Files",
    detail = "Open file search",
    glyph = "folder",
    commands = {
      {
        name = "search",
        detail = "Open file search",
        run = function(_)
          panel.enter(search())
        end,
      },
    },
  },
  {
    name = "clipboard",
    label = "Clipboard",
    detail = "Open clipboard history",
    glyph = "clipboard",
    commands = {
      {
        name = "history",
        detail = "Open clipboard history",
        run = function(_)
          panel.enter(history())
        end,
      },
    },
  },
  {
    name = "screenshot",
    label = "Screenshot",
    detail = "Capture an area, window, or screen",
    glyph = "command",
    commands = {
      {
        name = "area",
        detail = "Capture a selected area",
        run = function(_)
          panel.hide()
          screenshots.area()
        end,
      },
      {
        name = "window",
        detail = "Capture a selected window",
        run = function(_)
          panel.hide()
          screenshots.window()
        end,
      },
      {
        name = "screen",
        detail = "Capture every screen",
        run = function(_)
          panel.hide()
          screenshots.screen()
        end,
      },
    },
  },
}

---@return table[]
local function action_rows()
  local rows = {}
  for index, action in ipairs(actions) do
    local commands = {}
    for command_index, command in ipairs(action.commands) do
      commands[command_index] = {
        name = command.name,
        detail = command.detail,
        argument = command.argument,
      }
    end
    rows[index] = {
      name = action.name,
      label = action.label,
      detail = action.detail,
      glyph = action.glyph,
      commands = commands,
    }
  end
  return rows
end

---@param name string
---@param command_name string
---@param arg string
local function invoke(name, command_name, arg)
  for _, action in ipairs(actions) do
    if action.name == name then
      for _, command in ipairs(action.commands) do
        if command.name == command_name then
          command.run(arg)
          return
        end
      end
      return
    end
  end
end

---@param choice table|nil
local function activate(choice)
  if choice == nil then
    return
  end
  if choice.kind == "clipboard" then
    recency.touch(choice)
    panel.enter(history())
    return
  end
  if choice.kind == "files" then
    recency.touch(choice)
    panel.enter(search())
    return
  end

  panel.hide()
  recency.touch(choice)

  if choice.kind == "app" then
    hs.application.launchOrFocus(choice.path)
  elseif choice.kind == "pane" then
    local wezterm = settings().wezterm
    if wezterm then
      run({ wezterm, "cli", "--no-auto-start", "activate-pane", "--pane-id", tostring(choice.pane_id) })
    end
    hs.application.launchOrFocus("WezTerm")
  elseif choice.kind == "session" then
    local wezterm = settings().wezterm
    if wezterm and choice.path then
      run({ wezterm, "start", "--workspace", choice.text, "--cwd", choice.path })
    end
  elseif choice.kind == "tab" or choice.kind == "pref" then
    if choice.url then
      hs.urlevent.openURL(choice.url)
    end
  elseif choice.kind == "caffeinate" then
    panel.hide()
    caffeinate(choice.on == true)
    held.commands = command_rows()
    compose()
  elseif choice.kind == "command" then
    if choice.url then
      hs.urlevent.openURL(choice.url)
    elseif choice.run then
      hs.execute(choice.run, true)
    end
  end
end

---@return table
local function base()
  local rows = {}
  for _, source in ipairs(order) do
    for _, row in ipairs(held[source]) do
      rows[#rows + 1] = row
    end
  end
  return {
    name = "base",
    rows = recency.sort(rows),
    placeholder = "Search, + for actions, : for emoji, or ! for shell",
    choose = activate,
    shell = terminal,
    shellHistory = recency.recent("shell", 30),
    actions = action_rows(),
    invoke = invoke,
    -- The dataset itself is pushed once, at setup. Only the pick counts ride
    -- along here, because they change on every pick and the dataset does not.
    recent = emoji.recent(),
    pick = function(row)
      emoji.touch(row.code)
      emoji.copy(row.cp)
    end,
  }
end

-- Composes the base list and hands it to the panel, so a hidden panel already
-- holds the rows and the index the next open will use.
function compose()
  local on = caffeinated()
  panel.status(on and "Caffeinate on" or "Caffeinate off", on)
  panel.stage(base())
end

---@param rows table[]
---@return string
local function signature(rows)
  local parts = {}
  for index, row in ipairs(rows) do
    parts[index] = (row.text or "") .. "\1" .. (row.detail or "")
  end
  return table.concat(parts, "\2")
end

local mark = nil

-- Panes and sessions have no event source, so both polls run together. The list
-- is composed when the second result lands and only when its signature changed.
local function changed()
  held.entries = entry_rows()
  local now = table.concat({
    signature(held.panes),
    signature(held.sessions),
    signature(held.tabs),
    signature(held.entries),
    -- So the footer catches an assertion taken by something other than this
    -- launcher, such as `caffeinate` run in a shell.
    tostring(caffeinated()),
  }, "\3")
  if now == mark then
    return
  end
  mark = now
  compose()
end

local function refresh_live()
  local left = 2
  local function done(source)
    return function(rows)
      held[source] = rows
      left = left - 1
      if left > 0 then
        return
      end
      changed()
    end
  end
  pane_rows(done("panes"))
  session_rows(done("sessions"))
end

local function refresh_tabs()
  tab_rows(function(rows)
    held.tabs = rows
    changed()
  end)
end

local function refresh_tabs_soon()
  if tabs_pending then
    tabs_pending:stop()
  end
  tabs_pending = hs.timer.doAfter(settle_tabs, function()
    tabs_pending = nil
    refresh_tabs()
  end)
end

local apps_mark = nil

-- Re-reads the app directories and composes only when the list actually differs,
-- so the cadence below is free on the cycles that find nothing new.
local function rescan()
  apps = nil
  by_name = nil
  local rows = app_rows()
  local now = signature(rows)
  if now == apps_mark then
    return
  end
  apps_mark = now
  held.apps = rows
  compose()
end

-- Coalesces a burst of watcher events into one rescan.
local function rescan_soon()
  if pending then
    pending:stop()
  end
  pending = hs.timer.doAfter(settle_apps, function()
    pending = nil
    rescan()
  end)
end

local settled_at = 0

function M.toggle()
  local now = hs.timer.secondsSinceEpoch()
  if now - settled_at < settle_secs then
    return
  end
  settled_at = now
  if panel.visible() then
    panel.hide()
    return
  end
  panel.show()
end

function M.setup()
  clipboard.start()

  fzf.bin = settings().fzf
  files.fd = settings().fd
  files.timeout = settings().timeout
  files.roots = settings().fileRoots or {}
  files.excludes = settings().fileExcludes or {}
  files.cap = settings().fileCap or files.cap
  files.deadline = settings().fileDeadline or files.deadline
  files.index = fzf.index_path("files")
  fzf.ensure()

  panel.prewarm()
  panel.emoji(emoji.rows(settings().emoji))
  local shell = settings().shell
  if shell then
    run({ shell, "-fc", "print -rl -- ${(ok)commands}" }, function(out)
      local commands, seen = {}, {}
      for command in (out or ""):gmatch("[^\r\n]+") do
        if command:match("^[%w_][%w_.+%-]*$") and not seen[command] then
          seen[command] = true
          commands[#commands + 1] = command
        end
      end
      panel.shell_commands(commands)
    end)
  end

  hs.hotkey.bind({ "cmd" }, "space", function()
    M.toggle()
  end)

  held.commands = command_rows()
  held.apps = app_rows()
  apps_mark = signature(held.apps)
  held.entries = entry_rows()
  compose()

  -- Reading the panes costs about 700ms, because it parses a plist and an index
  -- of search terms per pane, so it runs after the list the hotkey already has.
  -- The panes change only with an OS update, so it runs once.
  hs.timer.doAfter(0, function()
    held.prefs = settings_panes.rows()
    compose()
  end)

  refresh_live()
  refresh_tabs()
  hs.timer.doEvery(live_secs, function()
    if panel.visible() then
      return
    end
    refresh_live()
  end)
  hs.timer.doEvery(tabs_secs, function()
    if panel.visible() then
      return
    end
    refresh_tabs()
  end)

  files.build(function()
    held.entries = entry_rows()
    compose()
  end)
  hs.timer.doEvery(files_secs, function()
    -- Never under an open panel: the page holds each row's position in the
    -- index, and a rebuild renumbers it.
    if panel.visible() then
      return
    end
    files.build()
  end)

  for _, dir in ipairs(settings().appDirs or {}) do
    local watcher = hs.pathwatcher.new(dir, rescan_soon)
    if watcher then
      watchers[#watchers + 1] = watcher
      watcher:start()
    end
  end

  local firefox = settings().firefoxProfileRoot
  if firefox then
    local watcher = hs.pathwatcher.new(firefox, refresh_tabs_soon)
    if watcher then
      watchers[#watchers + 1] = watcher
      watcher:start()
    end
  end

  hs.timer.doEvery(apps_secs, function()
    if panel.visible() then
      return
    end
    rescan()
  end)
end

return M
