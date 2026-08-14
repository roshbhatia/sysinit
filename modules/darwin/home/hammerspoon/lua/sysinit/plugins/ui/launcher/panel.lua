local fzf = require("sysinit.plugins.ui.launcher.fzf")

local M = {}

local page = hs.configdir .. "/lua/sysinit/plugins/ui/launcher/panel.html"

local width = 920
local top = 0.24

-- The page is only ever handed the rows it draws. A list can hold tens of
-- thousands of entries, and encoding all of them as JSON costs more than the
-- search it feeds.
local carry = 300

local view = nil
local watch = nil
local stack = {}
local loaded = false
local waiting = nil
local sent = {}
local written = {}
local queued = nil

---@param work fun()
local function ready(work)
  if loaded then
    work()
  else
    waiting = work
  end
end

---@param height number
---@return table
local function frame(height)
  local screen = hs.screen.mainScreen():frame()
  return {
    x = screen.x + (screen.w - width) / 2,
    y = screen.y + screen.h * top,
    w = width,
    h = height,
  }
end

-- `at` carries the true position of each row in its list, because the page is
-- given a subset and hands an index back when a row is chosen.
---@param rows table[]
---@param at number[]|nil
---@return table[], table<string, string>
local function transport(rows, at)
  local out, fresh = {}, {}
  for index, row in ipairs(rows) do
    local key = nil
    if row.icon then
      key = (row.kind or "") .. ":" .. (row.text or "")
      if not sent[key] then
        fresh[key] = row.icon
        sent[key] = true
      end
    end
    out[index] = {
      index = at and at[index] or index,
      title = row.text or "",
      sub = row.detail or "",
      kind = row.label or row.kind or "",
      icon = key,
      badge = row.badge,
      glyph = row.glyph,
    }
  end
  return out, fresh
end

---@return table|nil
local function current()
  return stack[#stack]
end

---@param list table
---@return string
local function index_name(list)
  return list.name or "list"
end

-- A list either hands over its rows outright or builds one on demand. The
-- second shape is for a list too large to hold as a table per row.
---@param list table
---@param index number
---@return table|nil
local function row_at(list, index)
  if list.row then
    return list.row(index)
  end
  return list.rows and list.rows[index] or nil
end

---@param list table
---@return number
local function size(list)
  if list.count then
    return list.count()
  end
  return list.rows and #list.rows or 0
end

-- fzf reads the rows from a file, so it is rewritten when the rows change
-- rather than once per keystroke. A list marked `indexed` writes that file
-- itself, and one that stamps its rows is only rewritten when the stamp moves.
---@param list table
local function reindex(list)
  if list.indexed then
    return
  end
  local name = index_name(list)
  if list.stamp ~= nil and written[name] == list.stamp then
    return
  end
  local haystacks = {}
  for index, row in ipairs(list.rows) do
    haystacks[index] = row.haystack or ((row.text or "") .. " " .. (row.detail or ""))
  end
  fzf.write_index(name, haystacks)
  written[name] = list.stamp
end

---@param fresh table<string, string>
local function icons(fresh)
  if next(fresh) ~= nil then
    view:evaluateJavaScript("setIcons(" .. hs.json.encode(fresh) .. ")")
  end
end

local function push()
  local list = current()
  if view == nil or not loaded or list == nil then
    return
  end
  local head = {}
  for index = 1, math.min(size(list), carry) do
    head[index] = row_at(list, index)
  end
  local out, fresh = transport(head, nil)
  icons(fresh)
  view:evaluateJavaScript("setRows(" .. hs.json.encode(out) .. ")")
end

local function present()
  local list = current()
  if view == nil or list == nil then
    return
  end
  push()
  view:evaluateJavaScript("open(" .. hs.json.encode({
    placeholder = list.placeholder or "Search",
    verb = list.verb or "Open",
    split = list.preview ~= nil,
    nested = #stack > 1,
    hints = list.hints,
  }) .. ")")
end

---@param list table
---@param body table
local function matched(list, body)
  fzf.filter({ name = index_name(list), query = body.query, limit = carry }, function(indices)
    if view == nil or current() ~= list then
      return
    end
    local rows, at = {}, {}
    for _, index in ipairs(indices or {}) do
      local row = row_at(list, index)
      if row then
        rows[#rows + 1] = row
        at[#at + 1] = index
      end
    end
    local out, fresh = transport(rows, at)
    icons(fresh)
    view:evaluateJavaScript("setMatches(" .. hs.json.encode({ seq = body.seq, rows = out }) .. ")")
  end)
end

---@param message table
local function received(message)
  local body = message and message.body or {}
  local list = current()
  if body.action == "loaded" then
    loaded = true
    if waiting then
      local work = waiting
      waiting = nil
      work()
    end
  elseif body.action == "height" then
    if view and view:hswindow() then
      view:frame(frame(body.height))
    end
  elseif body.action == "close" then
    M.hide()
  elseif body.action == "back" then
    if #stack > 1 then
      table.remove(stack)
      present()
    else
      M.hide()
    end
  elseif body.action == "filter" then
    if list ~= nil then
      matched(list, body)
    end
  elseif body.action == "preview" then
    local row = list and row_at(list, body.index)
    if row and list.preview then
      list.preview(row, function(html)
        if view and current() == list then
          view:evaluateJavaScript("setPreview(" .. hs.json.encode({ index = body.index, html = html }) .. ")")
        end
      end)
    end
  elseif body.action == "open" then
    local row = list and row_at(list, body.index)
    if row and list.choose then
      list.choose(row, body.mods or {})
    end
  end
end

local function build()
  local controller = hs.webview.usercontent.new("launcher")
  controller:setCallback(received)

  view = hs.webview.new(frame(400), { developerExtrasEnabled = false }, controller)
  view:windowStyle({ "borderless", "fullSizeContentView" })
  view:allowTextEntry(true)
  view:transparent(true)
  view:level(hs.drawing.windowLevels.modalPanel)
  view:shadow(true)

  local file = io.open(page, "r")
  if file then
    local html = file:read("*all")
    file:close()
    view:html(html)
  end
end

local function outside()
  if watch then
    watch:stop()
  end
  watch = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
    if view == nil or not view:isVisible() then
      return false
    end
    local at = event:location()
    local box = view:frame()
    local inside = at.x >= box.x and at.x <= box.x + box.w and at.y >= box.y and at.y <= box.y + box.h
    if not inside then
      M.hide()
    end
    return false
  end)
  watch:start()
end

-- The window and its page are built and loaded before the first hotkey, so
-- showing the panel is a show and a focus rather than a page load.
function M.prewarm()
  if view == nil then
    build()
  end
end

---@return boolean
function M.visible()
  return view ~= nil and view:isVisible()
end

-- Keeps a hidden list's rows current so the next show has nothing to compute.
---@param list table
function M.stage(list)
  -- The page holds each row's position in the list it was handed, so swapping
  -- the list under a visible panel would open the wrong row. It waits.
  if M.visible() then
    queued = list
    return
  end
  queued = nil
  reindex(list)
  if #stack > 1 then
    -- Inside a nested list, so refresh only the base it will return to.
    stack[1] = list
    return
  end
  stack = { list }
  if view ~= nil and loaded then
    push()
  end
end

---@param list table|nil
function M.show(list)
  M.prewarm()
  if list ~= nil then
    stack = { list }
    reindex(list)
  end
  view:show()
  ready(present)
  hs.timer.doAfter(0, function()
    local window = view and view:hswindow()
    if window then
      window:focus()
    end
  end)
  outside()
end

---@param list table
function M.enter(list)
  stack[#stack + 1] = list
  reindex(list)
  present()
end

function M.hide()
  if watch then
    watch:stop()
    watch = nil
  end
  if view then
    view:hide()
  end
  -- The next hotkey starts at the base list, not wherever this one was left.
  if #stack > 1 then
    stack = { stack[1] }
  end
  local held = queued
  queued = nil
  if held ~= nil then
    -- After the hide has settled, so the staging does not see a visible panel.
    hs.timer.doAfter(0, function()
      M.stage(held)
    end)
  end
end

return M
