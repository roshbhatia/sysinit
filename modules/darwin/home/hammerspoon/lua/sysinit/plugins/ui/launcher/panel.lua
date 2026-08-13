-- The window the launcher draws in: a borderless `hs.webview` holding `panel.html`. Not
-- `hs.chooser`, which is an AppKit list panel and takes no search field, no footer, and no
-- row shape of its own.
local M = {}

-- The page, installed beside this file by home-manager.
local page = hs.configdir .. "/lua/sysinit/plugins/ui/launcher/panel.html"

-- The panel's width and where its top edge sits, as a fraction of the screen. The margin is
-- the transparent border the page draws its shadow into, so the window is wider than the
-- panel by twice that.
local width = 750
local margin = 26
local top = 0.16

local view = nil
local watch = nil
local rows = {}
local chosen = nil
-- Whether the page has finished loading. Rows handed over before it has are dropped, so
-- what the first open wants to do waits in `waiting` until the page says it is ready.
local loaded = false
local waiting = nil

--- Run `work` once the page can take it.
---@param work fun()
local function ready(work)
  if loaded then
    work()
  else
    waiting = work
  end
end
-- The icons already handed to the page, keyed by the row that carries one. A data URI is
-- twelve kilobytes, so they are sent once and referenced by key afterwards.
local sent = {}

--- Where the window sits, given the height the page asked for.
---@param height number
---@return table
local function frame(height)
  local screen = hs.screen.mainScreen():frame()
  return {
    x = screen.x + (screen.w - width - margin * 2) / 2,
    y = screen.y + screen.h * top,
    w = width + margin * 2,
    h = height + margin * 2,
  }
end

--- What the page needs to draw one row, and any icon it has not been given yet.
---@param all table[]
---@return table[], table<string, string>
local function transport(all)
  local out, fresh = {}, {}
  for index, row in ipairs(all) do
    local key = nil
    if row.icon then
      key = (row.kind or "") .. ":" .. (row.text or "")
      if not sent[key] then
        fresh[key] = row.icon
        sent[key] = true
      end
    end
    out[index] = {
      index = index,
      title = row.text or "",
      sub = row.detail or "",
      kind = row.label or row.kind or "",
      icon = key,
      badge = row.badge,
    }
  end
  return out, fresh
end

--- Hand the current rows to the page.
local function push()
  if view == nil or not loaded then
    return
  end
  local out, fresh = transport(rows)
  if next(fresh) ~= nil then
    view:evaluateJavaScript("setIcons(" .. hs.json.encode(fresh) .. ")")
  end
  view:evaluateJavaScript("setRows(" .. hs.json.encode(out) .. ")")
end

--- Handle one message from the page.
---@param message table
local function received(message)
  local body = message and message.body or {}
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
  elseif body.action == "open" then
    local row = rows[body.index]
    M.hide()
    if row and chosen then
      chosen(row)
    end
  end
end

--- Build the window once and keep it, because loading the page costs more than showing it.
local function build()
  local controller = hs.webview.usercontent.new("launcher")
  controller:setCallback(received)

  view = hs.webview.new(frame(400), { developerExtrasEnabled = false }, controller)
  -- Borderless without `nonactivating`: a nonactivating window never becomes key, and the
  -- search field would take no typing at all.
  view:windowStyle({ "borderless", "fullSizeContentView" })
  view:allowTextEntry(true)
  view:transparent(true)
  view:level(hs.drawing.windowLevels.modalPanel)
  -- The window's shadow is square and the panel is not, so the page draws its own.
  view:shadow(false)

  local file = io.open(page, "r")
  if file then
    local html = file:read("*all")
    file:close()
    view:html(html)
  end
end

--- Close the panel when a click lands outside it, which is the other half of closing on a
--- lost focus.
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

--- Whether the panel is up.
---@return boolean
function M.visible()
  return view ~= nil and view:isVisible()
end

--- Replace the rows while the panel is up, for a source that has just answered.
---@param all table[]
function M.rows(all)
  rows = all
  push()
end

--- Show the panel with these rows, calling `cb` with the row that is opened.
---@param all table[]
---@param placeholder string
---@param cb fun(row: table)
function M.show(all, placeholder, cb)
  if view == nil then
    build()
  end
  rows = all
  chosen = cb
  view:show()
  -- Focus is taken a beat after showing, because focusing a window blocks until the system
  -- answers and doing it inline stalls whatever asked for the panel.
  hs.timer.doAfter(0, function()
    local window = view:hswindow()
    if window then
      window:focus()
    end
    ready(function()
      push()
      -- Wrapped in a table, because `hs.json.encode` takes only a table and a bare string
      -- raises rather than quoting itself.
      view:evaluateJavaScript("open(" .. hs.json.encode({ placeholder = placeholder }) .. ")")
    end)
  end)
  outside()
end

--- Hide the panel and stop watching for clicks.
function M.hide()
  if watch then
    watch:stop()
    watch = nil
  end
  if view then
    view:hide()
  end
end

return M
