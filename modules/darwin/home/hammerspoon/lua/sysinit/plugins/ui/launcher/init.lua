local ansi = require("sysinit.plugins.ui.launcher.ansi")
local json_loader = require("sysinit.pkg.utils.json_loader")
local clipboard = require("sysinit.plugins.ui.launcher.clipboard")
local panel = require("sysinit.plugins.ui.launcher.panel")
local recency = require("sysinit.plugins.ui.launcher.recency")

local M = {}

local apps = nil
local config = nil

---@return table
local function settings()
  if config == nil then
    config = json_loader.load_json_file(json_loader.get_config_path("launcher_config.json")) or {}
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
  local image = hs.image.iconForFile(path)
  if image == nil then
    return nil
  end
  local ok, encoded = pcall(function()
    return image:setSize({ w = 24, h = 24 }):encodeAsURLString()
  end)
  return ok and encoded or nil
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

---@param name string
---@return string|nil
local function app_icon(name)
  for _, row in ipairs(app_rows()) do
    if row.text == name then
      return row.icon
    end
  end
  return nil
end

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

---@return table[]
local function clipboard_rows()
  local held = clipboard.depth()
  if held == 0 then
    return {}
  end
  return {
    {
      text = "Clipboard History",
      detail = string.format("%d held", held),
      label = "Clipboard",
      badge = "C",
      kind = "clipboard",
    },
  }
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

---@return table[]
local function command_rows()
  local rows = {}
  for _, command in ipairs(settings().commands or {}) do
    rows[#rows + 1] = {
      text = command.label or "",
      detail = "",
      label = "Command",
      badge = "\u{2318}",
      kind = "command",
      run = command.run,
      url = command.url,
    }
  end
  return rows
end

---@return table
local function history()
  return {
    rows = clipboard.rows(),
    placeholder = "Search the clipboard history",
    verb = "Copy",
    preview = preview,
    choose = function(row)
      panel.hide()
      clipboard.restore(row.entry)
    end,
  }
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

  panel.hide()
  recency.touch(choice)

  if choice.kind == "app" then
    hs.application.launchOrFocus(choice.path)
  elseif choice.kind == "pane" then
    local wezterm = settings().wezterm
    if wezterm then
      run({ wezterm, "cli", "activate-pane", "--pane-id", tostring(choice.pane_id) })
    end
    hs.application.launchOrFocus("WezTerm")
  elseif choice.kind == "session" then
    local wezterm = settings().wezterm
    if wezterm and choice.path then
      run({ wezterm, "cli", "spawn", "--new-window", "--workspace", choice.text, "--cwd", choice.path })
      hs.application.launchOrFocus("WezTerm")
    end
  elseif choice.kind == "tab" then
    if choice.url then
      hs.urlevent.openURL(choice.url)
    end
  elseif choice.kind == "command" then
    if choice.url then
      hs.urlevent.openURL(choice.url)
    elseif choice.run then
      hs.execute(choice.run, true)
    end
  end
end

function M.toggle()
  if panel.visible() then
    panel.hide()
    return
  end
  local first = true
  M.gather(function(rows)
    if first then
      first = false
      panel.show({
        rows = rows,
        placeholder = "Search apps, panes, sessions, tabs, clipboard",
        choose = activate,
      })
    else
      panel.rows(rows)
    end
  end)
end

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
  fold(clipboard_rows())
  pane_rows(fold)
  session_rows(fold)
  tab_rows(fold)
end

function M.reindex()
  apps = nil
  config = nil
end

function M.setup()
  clipboard.start()

  hs.hotkey.bind({ "cmd" }, "space", function()
    M.toggle()
  end)

  hs.timer.doAfter(2, app_rows)

  for _, dir in ipairs(settings().appDirs or {}) do
    local watcher = hs.pathwatcher.new(dir, function()
      apps = nil
      hs.timer.doAfter(2, app_rows)
    end)
    if watcher then
      watcher:start()
    end
  end
end

return M
