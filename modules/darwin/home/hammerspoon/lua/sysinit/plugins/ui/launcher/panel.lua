local fzf = require("sysinit.plugins.ui.launcher.fzf")
local json_loader = require("sysinit.pkg.utils.json_loader")

local M = {}

local dir = hs.configdir .. "/lua/sysinit/plugins/ui/launcher/page"

local width = 920
local top = 0.24

-- A list too large to hold in the page is matched by fzf, and only this many of
-- its matches are carried back. The page draws a fraction of them; the rest are
-- there so the list can be scrolled.
local carry = 300

-- How long the closing animation runs before the window is taken away. Kept in
-- step with the `sink` keyframes in the page.
local closing_secs = 0.11
-- How long the panel takes to ease to a new height, after which the window can
-- safely shrink to match. Kept in step with the `height` transition.
local settle_secs = 0.2

local view = nil
local watch = nil
local stack = {}
local loaded = false
local waiting = nil
local sent = {}
local written = {}
local queued = nil
local closing = nil
local shrinking = nil
local height = 0
local pushed = nil
local prepared = nil
local warming = false
local status = nil

-- The window is on screen during the warm-up below without anything being drawn
-- into it, so `isVisible` alone would report an open panel to a hotkey that has
-- not opened one yet.
---@return boolean
local function onscreen()
  return view ~= nil and view:isVisible() and not warming
end

---@param work fun()
local function ready(work)
  if loaded then
    work()
  else
    waiting = work
  end
end

---@param path string
---@return string
local function slurp(path)
  local file = io.open(path, "r")
  if file == nil then
    return ""
  end
  local text = file:read("*all")
  file:close()
  return text
end

---@param hex string
---@param alpha number
---@return string
local function rgba(hex, alpha)
  local r, g, b = tostring(hex):match("^#?(%x%x)(%x%x)(%x%x)$")
  if r == nil then
    return "transparent"
  end
  return string.format("rgba(%d, %d, %d, %g)", tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), alpha)
end

-- Each variable the page draws with, as a slot and the alpha it is laid over the
-- panel at. The alphas are the ones the stylesheet was tuned with; only the
-- colour underneath them comes from the scheme.
--
-- `bg` does not follow `theme.transparency.opacity`. That setting is 0.9, tuned
-- for a terminal sitting over a desktop, and the panel sits over whatever window
-- was in front: at 0.9 a browser page behind it is legible straight through the
-- rows. 0.96 is what the stylesheet shipped with and what the panel needs.
local paints = {
  { "bg", "base00", 0.96 },
  { "edge", "base02", 0.9 },
  { "line", "base02", 0.7 },
  { "text", "base05", 1 },
  { "muted", "base04", 0.85 },
  -- base03 is the scheme's dim slot and reads at 2.5:1 on gruvbox, which is too
  -- faint for a subtitle, so the faint role is base04 held back instead.
  { "faint", "base04", 0.6 },
  -- Solid, so the selected row reads as a block rather than as a tint over
  -- whatever shows through the panel.
  { "sel", "base02", 1 },
  { "badge", "base02", 0.9 },
  { "cap", "base02", 0.8 },
  { "accent", "base0D", 1 },
}

-- The stylesheet carries a dark default, so a host with no scheme written out
-- still draws. This overrides it, and is empty when there is nothing to override
-- it with.
---@return string
local function palette()
  local config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
  local scheme = config and config.base16
  if scheme == nil then
    return ""
  end
  -- The scheme decides the colours and the table above decides the alphas, so
  -- the only thing left to read is whether the host wants transparency at all.
  local opaque = (config.transparency or {}).enable == false
  local lines = {}
  for _, paint in ipairs(paints) do
    local name, slot, alpha = paint[1], paint[2], paint[3]
    lines[#lines + 1] = string.format("--%s: %s;", name, rgba(scheme[slot], opaque and 1 or alpha))
  end
  return ":root {\n" .. table.concat(lines, "\n") .. "\n}"
end

-- The page is one document by the time it is loaded, because `view:html` takes
-- markup and not a directory, and a relative <script src> in it resolves against
-- nothing. Splitting the source is for whoever reads it.
---@return string
local function document()
  local html = slurp(dir .. "/panel.html")
  local built = html:gsub("/%* INCLUDE ([%w_.%-]+) %*/", function(name)
    return slurp(dir .. "/" .. name)
  end)
  return (built:gsub("/%* THEME %*/", palette))
end

---@param h number
---@return table
local function frame(h)
  local screen = hs.screen.mainScreen():frame()
  return {
    x = screen.x + (screen.w - width) / 2,
    y = screen.y + screen.h * top,
    w = width,
    h = h,
  }
end

-- `at` carries the true position of each row in its list, because a list matched
-- by fzf hands the page a subset and gets an index back when a row is chosen.
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
      terms = row.terms,
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

-- A list either hands over its rows outright or builds one on demand. The second
-- shape is for a list too large to hold as a table per row, and its rows arrive
-- with the text fzf matched, so nothing has to be held to look them up.
---@param list table
---@param index number
---@param text string|nil
---@return table|nil
local function row_at(list, index, text)
  if list.row then
    return list.row(index, text)
  end
  return list.rows and list.rows[index] or nil
end

-- What the page is given when a list opens. An indexed list is capped, because
-- its rows run to six figures; every other list is handed over whole so the page
-- can match it without asking.
---@param list table
---@return table[]
local function opening_rows(list)
  if list.indexed then
    return list.head and list.head(carry) or {}
  end
  return list.rows or {}
end

-- fzf reads the rows from a file, so it is rewritten when the rows change rather
-- than once per keystroke. A list marked `indexed` writes that file itself, and
-- one that stamps its rows is only rewritten when the stamp moves.
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
  local out, fresh = transport(opening_rows(list), nil)
  icons(fresh)
  view:evaluateJavaScript("setRows(" .. hs.json.encode(out) .. ")")
  pushed = list
end

-- Resets the page for the list it is about to show. Called while the window is
-- hidden, so the rows, the height and the query are all already right by the
-- time anything is drawn.
local function prepare()
  local list = current()
  if view == nil or list == nil then
    return
  end
  -- Staging already sent these rows in the usual case, and they run to a few
  -- hundred, so they are not encoded again for every open.
  if pushed ~= list then
    push()
  end
  view:evaluateJavaScript("open(" .. hs.json.encode({
    placeholder = list.placeholder or "Search",
    verb = list.verb or "Open",
    split = list.preview ~= nil,
    nested = #stack > 1,
    inpage = not list.indexed,
    shell = list.shell ~= nil,
    hints = list.hints,
    -- Carried on every open rather than pushed when it changes, because it only
    -- ever changes while the panel is hidden.
    status = status or { text = "", on = false },
  }) .. ")")
  prepared = list
end

---@param list table
---@param body table
local function matched(list, body)
  fzf.filter({ name = index_name(list), query = body.query, limit = carry }, function(hits)
    if view == nil or current() ~= list then
      return
    end
    local rows, at = {}, {}
    for _, hit in ipairs(hits or {}) do
      local row = row_at(list, hit.index, hit.text)
      if row then
        rows[#rows + 1] = row
        at[#at + 1] = hit.index
      end
    end
    local out, fresh = transport(rows, at)
    icons(fresh)
    view:evaluateJavaScript("setMatches(" .. hs.json.encode({ seq = body.seq, rows = out }) .. ")")
  end)
end

-- Growing has to reach the window before the panel is drawn into the new space,
-- and shrinking has to reach it after, or the panel is clipped while it eases.
--
-- The frame is set whether or not the window is on screen. Staging fits the
-- window to its rows while the panel is still hidden, which is what leaves
-- nothing to resize when the hotkey is pressed; skipping the hidden case left
-- every open at the size the window was first built with.
---@param wanted number
---@param instant boolean
local function resize(wanted, instant)
  if shrinking then
    shrinking:stop()
    shrinking = nil
  end
  if view == nil then
    return
  end
  local was = height
  height = wanted
  if instant or wanted >= was then
    view:frame(frame(wanted))
    return
  end
  shrinking = hs.timer.doAfter(settle_secs, function()
    shrinking = nil
    if view then
      view:frame(frame(height))
    end
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
    resize(body.height, body.instant == true)
  elseif body.action == "close" then
    M.hide()
  elseif body.action == "copy" then
    hs.pasteboard.setContents(body.text or "")
    M.hide()
  elseif body.action == "back" then
    if #stack > 1 then
      table.remove(stack)
      prepare()
      view:evaluateJavaScript("reveal()")
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
  elseif body.action == "shell" then
    M.hide()
    if list and list.shell then
      list.shell(body.cmd or "")
    end
  elseif body.action == "open" then
    local row = list and row_at(list, body.index, body.text)
    if row and list.choose then
      list.choose(row, body.mods or {})
    end
  end
end

local function build()
  local controller = hs.webview.usercontent.new("launcher")
  controller:setCallback(received)

  view = hs.webview.new(frame(400), { developerExtrasEnabled = false }, controller)
  -- `nonactivating` lets the panel become the key window without activating
  -- Hammerspoon. That activation is a synchronous wait on the window server:
  -- usually under 100ms, but measured here blocking for up to 4.9 seconds while
  -- the window server was busy, with Hammerspoon using no CPU. The hotkey cannot
  -- fire during that wait, so the launcher appeared frozen. Without activation
  -- there is no such wait, and the app the user was in stays frontmost.
  view:windowStyle({ "borderless", "fullSizeContentView", "nonactivating" })
  view:allowTextEntry(true)
  view:transparent(true)
  view:level(hs.drawing.windowLevels.modalPanel)
  view:shadow(true)
  view:html(document())
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

-- Takes the window away and puts the page back to its resting state. Split from
-- `M.hide` so the closing animation has somewhere to finish, and so a hotkey
-- pressed during that animation can finish it early rather than wait it out.
local function withdraw()
  if closing then
    closing:stop()
    closing = nil
  end
  if view == nil then
    return
  end
  view:hide()
  view:evaluateJavaScript("reset()")
  -- The next hotkey starts at the base list, not wherever this one was left.
  if #stack > 1 then
    stack = { stack[1] }
  end
  -- Everything the next open needs is done here, with nothing on screen to see
  -- it: the rows, the query, and the window's size. That leaves the hotkey with
  -- one small call to make, which is why the panel appears rather than assembles.
  local held = queued
  queued = nil
  if held ~= nil then
    M.stage(held)
  else
    prepare()
  end
end

-- The window and its page are built and loaded before the first hotkey, so
-- showing the panel is a show and a focus rather than a page load.
function M.prewarm()
  if view ~= nil then
    return
  end
  build()
  -- A webview that has never been on screen has no layers to draw with, and
  -- builds them during the first show, which is the one open that has to be
  -- quick. Showing it once costs nothing to look at, because the panel is
  -- invisible until it is revealed.
  ready(function()
    warming = true
    view:show()
    hs.timer.doAfter(0.4, function()
      if not warming then
        return
      end
      warming = false
      view:hide()
    end)
  end)
end

-- What the footer says about the machine rather than about the selected row.
---@param text string
---@param on boolean
function M.status(text, on)
  status = { text = text, on = on == true }
end

---@return boolean
function M.visible()
  return onscreen() and closing == nil
end

-- Keeps a hidden list's rows current so the next show has nothing to compute.
---@param list table
function M.stage(list)
  -- The page holds each row's position in the list it was handed, so swapping
  -- the list under a visible panel would open the wrong row. It waits.
  if onscreen() then
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
    prepare()
  end
end

---@param list table|nil
function M.show(list)
  M.prewarm()
  -- A hotkey during the closing animation is an open, so the close is finished
  -- now rather than left to land on top of it.
  if closing ~= nil then
    withdraw()
  end
  warming = false
  if list ~= nil then
    stack = { list }
    reindex(list)
  end
  ready(function()
    -- Staging and the last close leave the page already reset, so the usual open
    -- is a show and a reveal. Preparing here is the fallback for the first one.
    if prepared ~= current() then
      prepare()
    end
    view:show()
    view:evaluateJavaScript("reveal()")
    -- No focus call from here: a nonactivating panel becomes key on its own, and
    -- asking for focus is what triggered the activation wait. The page focuses
    -- its own field, which is what typing needs.
    outside()
  end)
end

---@param list table
function M.enter(list)
  stack[#stack + 1] = list
  reindex(list)
  prepare()
  view:evaluateJavaScript("reveal()")
end

function M.hide()
  if not M.visible() then
    return
  end
  if watch then
    watch:stop()
    watch = nil
  end
  view:evaluateJavaScript("dismiss()")
  closing = hs.timer.doAfter(closing_secs, withdraw)
end

return M
