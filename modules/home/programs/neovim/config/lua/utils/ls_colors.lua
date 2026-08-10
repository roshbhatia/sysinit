local M = {}

local COLOR_256 = {}

do
  local ansi = {
    [0] = "#000000",
    "#cc0000",
    "#4e9a06",
    "#c4a000",
    "#3465a4",
    "#75507b",
    "#06989a",
    "#d3d7cf",
  }
  local bright = {
    [0] = "#555753",
    "#ef2929",
    "#8ae234",
    "#fce94f",
    "#729fcf",
    "#ad7fa8",
    "#34e2e2",
    "#eeeeec",
  }
  for i = 0, 7 do
    COLOR_256[i] = ansi[i]
    COLOR_256[i + 8] = bright[i]
  end

  local cube = { 0, 95, 135, 175, 215, 255 }
  for r = 0, 5 do
    for g = 0, 5 do
      for b = 0, 5 do
        COLOR_256[16 + 36 * r + 6 * g + b] = string.format("#%02x%02x%02x", cube[r + 1], cube[g + 1], cube[b + 1])
      end
    end
  end

  for i = 232, 255 do
    local v = 8 + 10 * (i - 232)
    COLOR_256[i] = string.format("#%02x%02x%02x", v, v, v)
  end
end

local SGR_FG = {} -- 30-37 → 0-7
local SGR_FG_BRIGHT = {} -- 90-97 → 8-15
for i = 0, 7 do
  SGR_FG[30 + i] = i
  SGR_FG_BRIGHT[90 + i] = i + 8
end

--- @param attr string semicolon-separated SGR codes
--- @return { fg: string|nil, bg: string|nil, bold: boolean }
local function parse_sgr(attr)
  local result = { bold = false }
  local codes = {}
  for c in attr:gmatch("[^;]+") do
    codes[#codes + 1] = tonumber(c) or 0
  end

  local i = 1
  while i <= #codes do
    local c = codes[i]

    if c == 1 then
      result.bold = true
    elseif c == 38 and codes[i + 1] == 2 then
      local r, g, b = codes[i + 2], codes[i + 3], codes[i + 4]
      if r and g and b then
        result.fg = string.format("#%02x%02x%02x", r, g, b)
      end
      i = i + 4
    elseif c == 48 and codes[i + 1] == 2 then
      local r, g, b = codes[i + 2], codes[i + 3], codes[i + 4]
      if r and g and b then
        result.bg = string.format("#%02x%02x%02x", r, g, b)
      end
      i = i + 4
    elseif c == 38 and codes[i + 1] == 5 then
      local n = codes[i + 2]
      if n and COLOR_256[n] then
        result.fg = COLOR_256[n]
      end
      i = i + 2
    elseif c == 48 and codes[i + 1] == 5 then
      local n = codes[i + 2]
      if n and COLOR_256[n] then
        result.bg = COLOR_256[n]
      end
      i = i + 2
    elseif SGR_FG[c] then
      result.fg = COLOR_256[SGR_FG[c]]
    elseif SGR_FG_BRIGHT[c] then
      result.fg = COLOR_256[SGR_FG_BRIGHT[c]]
    end

    i = i + 1
  end

  return result
end

--- @return table<string, { fg: string|nil, bg: string|nil, bold: boolean }>
function M.parse()
  local raw = vim.env.LS_COLORS
  if not raw or raw == "" then
    return {}
  end

  local entries = {}
  for entry in raw:gmatch("[^:]+") do
    local key, val = entry:match("^([^=]+)=(.+)$")
    if key and val then
      entries[key] = parse_sgr(val)
    end
  end
  return entries
end

local TYPE_TO_SLOT = {
  di = "blue", -- directories
  ln = "teal", -- symlinks
  so = "mauve", -- sockets
  pi = "yellow", -- FIFOs
  ex = "green", -- executables
  bd = "peach", -- block devices
  cd = "peach", -- char devices
  ["or"] = "red", -- orphan symlinks
  mi = "maroon", -- missing targets
}

--- @param entries table<string, { fg: string|nil }> output of M.parse()
--- @return table<string, string> slot→hex
function M.extract_palette(entries)
  local palette = {}
  for ftype, slot in pairs(TYPE_TO_SLOT) do
    local e = entries[ftype]
    if e and e.fg then
      palette[slot] = e.fg
    end
  end
  return palette
end

return M
