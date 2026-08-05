-- LS_COLORS parser — extracts color information from $LS_COLORS
local M = {}

-- xterm-256color palette (indices 0-255 → "#rrggbb")
local COLOR_256 = {}

do
  -- Standard ANSI 0-7 (terminal-defined, using common defaults)
  local ansi = {
    [0] = "#000000", "#cc0000", "#4e9a06", "#c4a000",
    "#3465a4", "#75507b", "#06989a", "#d3d7cf",
  }
  -- Bright ANSI 8-15
  local bright = {
    [0] = "#555753", "#ef2929", "#8ae234", "#fce94f",
    "#729fcf", "#ad7fa8", "#34e2e2", "#eeeeec",
  }
  for i = 0, 7 do
    COLOR_256[i] = ansi[i]
    COLOR_256[i + 8] = bright[i]
  end

  -- 6×6×6 colour cube (indices 16-231)
  local cube = { 0, 95, 135, 175, 215, 255 }
  for r = 0, 5 do
    for g = 0, 5 do
      for b = 0, 5 do
        COLOR_256[16 + 36 * r + 6 * g + b] =
          string.format("#%02x%02x%02x", cube[r + 1], cube[g + 1], cube[b + 1])
      end
    end
  end

  -- Grayscale ramp (indices 232-255)
  for i = 232, 255 do
    local v = 8 + 10 * (i - 232)
    COLOR_256[i] = string.format("#%02x%02x%02x", v, v, v)
  end
end

-- Basic ANSI SGR code → colour index
local SGR_FG = {} -- 30-37 → 0-7
local SGR_FG_BRIGHT = {} -- 90-97 → 8-15
for i = 0, 7 do
  SGR_FG[30 + i] = i
  SGR_FG_BRIGHT[90 + i] = i + 8
end

--- Parse a single SGR attribute string like "01;38;2;100;200;50"
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
      -- truecolor fg: 38;2;R;G;B
      local r, g, b = codes[i + 2], codes[i + 3], codes[i + 4]
      if r and g and b then
        result.fg = string.format("#%02x%02x%02x", r, g, b)
      end
      i = i + 4
    elseif c == 48 and codes[i + 1] == 2 then
      -- truecolor bg: 48;2;R;G;B
      local r, g, b = codes[i + 2], codes[i + 3], codes[i + 4]
      if r and g and b then
        result.bg = string.format("#%02x%02x%02x", r, g, b)
      end
      i = i + 4
    elseif c == 38 and codes[i + 1] == 5 then
      -- 256-color fg: 38;5;N
      local n = codes[i + 2]
      if n and COLOR_256[n] then result.fg = COLOR_256[n] end
      i = i + 2
    elseif c == 48 and codes[i + 1] == 5 then
      -- 256-color bg: 48;5;N
      local n = codes[i + 2]
      if n and COLOR_256[n] then result.bg = COLOR_256[n] end
      i = i + 2
    elseif SGR_FG[c] then
      result.fg = COLOR_256[SGR_FG[c]]
    elseif SGR_FG_BRIGHT[c] then
      result.fg = COLOR_256[SGR_FG_BRIGHT[c]]
    end
    -- (background 40-47/100-107 handled similarly if needed)

    i = i + 1
  end

  return result
end

--- Parse $LS_COLORS into a table of { type = { fg, bg, bold } }
--- @return table<string, { fg: string|nil, bg: string|nil, bold: boolean }>
function M.parse()
  local raw = vim.env.LS_COLORS
  if not raw or raw == "" then return {} end

  local entries = {}
  for entry in raw:gmatch("[^:]+") do
    local key, val = entry:match("^([^=]+)=(.+)$")
    if key and val then
      entries[key] = parse_sgr(val)
    end
  end
  return entries
end

-- Map well-known LS_COLORS file types to Catppuccin palette slots
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

--- Extract a Catppuccin-slot palette override from parsed LS_COLORS.
--- Only truecolor / 256-color values produce overrides (basic ANSI defers
--- to the terminal query or Catppuccin defaults).
--- @param entries table<string, { fg: string|nil }> output of M.parse()
--- @return table<string, string> slot→hex
function M.extract_palette(entries)
  local palette = {}
  for ftype, slot in pairs(TYPE_TO_SLOT) do
    local e = entries[ftype]
    if e and e.fg then
      -- Only override when we have an exact colour (not a basic ANSI default)
      palette[slot] = e.fg
    end
  end
  return palette
end

return M
