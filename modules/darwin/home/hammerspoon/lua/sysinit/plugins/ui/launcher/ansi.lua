-- Colour escapes to markup. `bat` writes its highlighting as ANSI sequences and the preview
-- pane is a web page, so one has to be translated into the other.
local M = {}

--- One xterm palette entry as a hex colour. The first sixteen are the terminal's own, then
--- a six by six by six cube, then twenty-four greys.
---@param index number
---@return string
local function palette(index)
  local basic = {
    "#000000",
    "#cc0000",
    "#4e9a06",
    "#c4a000",
    "#3465a4",
    "#75507b",
    "#06989a",
    "#d3d7cf",
    "#555753",
    "#ef2929",
    "#8ae234",
    "#fce94f",
    "#729fcf",
    "#ad7fa8",
    "#34e2e2",
    "#eeeeec",
  }
  if index < 16 then
    return basic[index + 1]
  end
  if index < 232 then
    local steps = { 0, 95, 135, 175, 215, 255 }
    local at = index - 16
    local red = steps[math.floor(at / 36) % 6 + 1]
    local green = steps[math.floor(at / 6) % 6 + 1]
    local blue = steps[at % 6 + 1]
    return string.format("#%02x%02x%02x", red, green, blue)
  end
  local grey = 8 + (index - 232) * 10
  return string.format("#%02x%02x%02x", grey, grey, grey)
end

--- The text a page can hold without reading it as markup.
---@param text string
---@return string
local function escape(text)
  return (text:gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

--- Read one SGR sequence into the style it sets. Only the foreground colours and bold are
--- kept: a background from `bat` would fight the panel's own, and the rest do not survive
--- the trip to a page anyway.
---@param codes string
---@param style table
local function apply(codes, style)
  local parts = {}
  for part in codes:gmatch("[^;]+") do
    parts[#parts + 1] = tonumber(part) or 0
  end
  if #parts == 0 then
    parts = { 0 }
  end
  local at = 1
  while at <= #parts do
    local code = parts[at]
    if code == 0 then
      style.color, style.bold = nil, false
    elseif code == 1 then
      style.bold = true
    elseif code == 22 then
      style.bold = false
    elseif code == 39 then
      style.color = nil
    elseif code >= 30 and code <= 37 then
      style.color = palette(code - 30)
    elseif code >= 90 and code <= 97 then
      style.color = palette(code - 90 + 8)
    elseif code == 38 then
      if parts[at + 1] == 5 then
        style.color = palette(parts[at + 2] or 0)
        at = at + 2
      elseif parts[at + 1] == 2 then
        style.color = string.format("#%02x%02x%02x", parts[at + 2] or 0, parts[at + 3] or 0, parts[at + 4] or 0)
        at = at + 4
      end
    end
    at = at + 1
  end
end

--- Translate a stretch of coloured terminal output into markup.
---@param text string
---@return string
function M.html(text)
  local out = {}
  local style = { bold = false }
  local open = false
  local at = 1

  local function close()
    if open then
      out[#out + 1] = "</span>"
      open = false
    end
  end

  local function start()
    if style.color == nil and not style.bold then
      return
    end
    local css = {}
    if style.color then
      css[#css + 1] = "color:" .. style.color
    end
    if style.bold then
      css[#css + 1] = "font-weight:600"
    end
    out[#out + 1] = '<span style="' .. table.concat(css, ";") .. '">'
    open = true
  end

  while true do
    local from, to, codes = text:find("\27%[([%d;]*)m", at)
    local plain = text:sub(at, (from or 0) - 1)
    if plain ~= "" then
      out[#out + 1] = escape(plain)
    end
    if from == nil then
      break
    end
    close()
    apply(codes, style)
    start()
    at = to + 1
  end
  close()
  return table.concat(out)
end

return M
