local M = {}

local page = hs.configdir .. "/lua/sysinit/plugins/ui/launcher/panel.html"

local width = 750
local top = 0.16

local view = nil
local watch = nil
local stack = {}
local loaded = false
local waiting = nil

---@param work fun()
local function ready(work)
  if loaded then
    work()
  else
    waiting = work
  end
end
local sent = {}

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

---@return table|nil
local function current()
  return stack[#stack]
end

local function push()
  local list = current()
  if view == nil or not loaded or list == nil then
    return
  end
  local out, fresh = transport(list.rows)
  if next(fresh) ~= nil then
    view:evaluateJavaScript("setIcons(" .. hs.json.encode(fresh) .. ")")
  end
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
  }) .. ")")
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
  elseif body.action == "preview" then
    local row = list and list.rows[body.index]
    if row and list.preview then
      list.preview(row, function(html)
        if view and current() == list then
          view:evaluateJavaScript("setPreview(" .. hs.json.encode({ index = body.index, html = html }) .. ")")
        end
      end)
    end
  elseif body.action == "open" then
    local row = list and list.rows[body.index]
    if row and list.choose then
      list.choose(row)
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

---@return boolean
function M.visible()
  return view ~= nil and view:isVisible()
end

---@param all table[]
function M.rows(all)
  local list = current()
  if list and #stack == 1 then
    list.rows = all
    push()
  end
end

---@param list table
function M.show(list)
  if view == nil then
    build()
  end
  stack = { list }
  view:show()
  hs.timer.doAfter(0, function()
    local window = view:hswindow()
    if window then
      window:focus()
    end
    ready(present)
  end)
  outside()
end

---@param list table
function M.enter(list)
  stack[#stack + 1] = list
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
end

return M
