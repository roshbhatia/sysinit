-- Palette builder — derives a complete Catppuccin palette from terminal
-- colours and LS_COLORS using semantic mapping and contrast-aware ramps.
local M = {}

-- Default xterm ANSI hex values (baseline when OSC queries fail)
local DEFAULT_ANSI = {
  [0]  = "#000000", [1]  = "#cc0000", [2]  = "#4e9a06", [3]  = "#c4a000",
  [4]  = "#3465a4", [5]  = "#75507b", [6]  = "#06989a", [7]  = "#d3d7cf",
  [8]  = "#555753", [9]  = "#ef2929", [10] = "#8ae234", [11] = "#fce94f",
  [12] = "#729fcf", [13] = "#ad7fa8", [14] = "#34e2e2", [15] = "#eeeeec",
}

-- Accent target hues (degrees) for semantic mapping
local ACCENT_TARGETS = {
  red = 0,
  maroon = 350,
  peach = 30,
  yellow = 55,
  green = 120,
  teal = 170,
  sky = 200,
  sapphire = 220,
  blue = 240,
  mauve = 275,
  pink = 320,
}

local ACCENT_ORDER = {
  "red",
  "maroon",
  "peach",
  "yellow",
  "green",
  "teal",
  "sky",
  "sapphire",
  "blue",
  "mauve",
  "pink",
}

local ACCENT_SLOTS = {
  red = true,
  maroon = true,
  peach = true,
  yellow = true,
  green = true,
  teal = true,
  sky = true,
  sapphire = true,
  blue = true,
  mauve = true,
  pink = true,
}

local MIN_TEXT_CONTRAST_FLOOR = 3.0
local MAX_TEXT_CONTRAST_TARGET = 4.5

-- Position of each ramp colour between crust (0.0) and text (1.0).
-- Ratios derived from Catppuccin Mocha's grayscale progression.
local RAMP = {
  crust    = 0.000,
  mantle   = 0.042,
  base     = 0.079,
  surface0 = 0.180,
  surface1 = 0.284,
  surface2 = 0.385,
  overlay0 = 0.489,
  overlay1 = 0.590,
  overlay2 = 0.694,
  subtext0 = 0.795,
  subtext1 = 0.899,
  text     = 1.000,
}

--- Convert "#rrggbb" → r, g, b (0-255)
local function hex_to_rgb(hex)
  hex = hex:gsub("^#", "")
  return tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16)
end

local function clamp_channel(value)
  if value < 0 then return 0 end
  if value > 255 then return 255 end
  return math.floor(value + 0.5)
end

--- Linearly interpolate between two hex colours.
--- @param c1 string "#rrggbb"
--- @param c2 string "#rrggbb"
--- @param t  number  0.0 = c1, 1.0 = c2
--- @return string "#rrggbb"
function M.interpolate(c1, c2, t)
  local r1, g1, b1 = hex_to_rgb(c1)
  local r2, g2, b2 = hex_to_rgb(c2)
  local r = clamp_channel(r1 + (r2 - r1) * t)
  local g = clamp_channel(g1 + (g2 - g1) * t)
  local b = clamp_channel(b1 + (b2 - b1) * t)
  return string.format("#%02x%02x%02x", r, g, b)
end

--- Decide if a background colour is dark or light (ITU-R BT.709 luminance).
--- @param bg string "#rrggbb"
--- @return "dark"|"light"
function M.detect_dark_light(bg)
  local r, g, b = hex_to_rgb(bg)
  local lum = 0.2126 * r / 255 + 0.7152 * g / 255 + 0.0722 * b / 255
  return lum < 0.5 and "dark" or "light"
end

local function channel_to_linear(value)
  local c = value / 255
  if c <= 0.03928 then
    return c / 12.92
  end
  return ((c + 0.055) / 1.055) ^ 2.4
end

local function relative_luminance(hex)
  local r, g, b = hex_to_rgb(hex)
  return 0.2126 * channel_to_linear(r)
    + 0.7152 * channel_to_linear(g)
    + 0.0722 * channel_to_linear(b)
end

local function contrast_ratio(c1, c2)
  local l1 = relative_luminance(c1)
  local l2 = relative_luminance(c2)
  if l1 < l2 then l1, l2 = l2, l1 end
  return (l1 + 0.05) / (l2 + 0.05)
end

local function max_contrast(base, list)
  local best = 0
  for _, cand in ipairs(list) do
    if cand.hex ~= base then
      local ratio = contrast_ratio(base, cand.hex)
      if ratio > best then
        best = ratio
      end
    end
  end
  return best
end

local function target_text_contrast(base, candidates)
  local target = math.min(MAX_TEXT_CONTRAST_TARGET, max_contrast(base, candidates))
  if target < MIN_TEXT_CONTRAST_FLOOR then
    target = MIN_TEXT_CONTRAST_FLOOR
  end
  return target
end

local function pick_base_color(candidates, is_dark)
  local pool = {}
  for _, cand in ipairs(candidates) do
    if cand.sat <= 0.2 then
      pool[#pool + 1] = cand
    end
  end
  if #pool == 0 then
    pool = candidates
  end

  local chosen, chosen_lum
  for _, cand in ipairs(pool) do
    local lum = relative_luminance(cand.hex)
    if not chosen then
      chosen = cand.hex
      chosen_lum = lum
    elseif is_dark and lum < chosen_lum then
      chosen = cand.hex
      chosen_lum = lum
    elseif not is_dark and lum > chosen_lum then
      chosen = cand.hex
      chosen_lum = lum
    end
  end

  return chosen
end

local function rgb_to_hsl(hex)
  local r, g, b = hex_to_rgb(hex)
  r, g, b = r / 255, g / 255, b / 255

  local max_c = math.max(r, g, b)
  local min_c = math.min(r, g, b)
  local delta = max_c - min_c

  local h = 0
  if delta ~= 0 then
    if max_c == r then
      h = ((g - b) / delta) % 6
    elseif max_c == g then
      h = (b - r) / delta + 2
    else
      h = (r - g) / delta + 4
    end
    h = h * 60
    if h < 0 then h = h + 360 end
  end

  local l = (max_c + min_c) / 2
  local s = 0
  if delta ~= 0 then
    s = delta / (1 - math.abs(2 * l - 1))
  end

  return h, s, l
end

local function hue_distance(a, b)
  local diff = math.abs(a - b)
  return math.min(diff, 360 - diff)
end

local function collect_ansi_colors(terminal_colors)
  local colors = {}
  local seen = {}
  for i = 0, 15 do
    local hex = terminal_colors[i] or DEFAULT_ANSI[i]
    if hex and not seen[hex] then
      seen[hex] = true
      local h, s, l = rgb_to_hsl(hex)
      colors[#colors + 1] = { hex = hex, hue = h, sat = s, lightness = l }
    end
  end
  return colors
end

local function pick_text_color(base, candidates)
  local function pick_from(list)
    local choice, ratio = nil, -1
    for _, cand in ipairs(list) do
      if cand.hex ~= base then
        local current = contrast_ratio(base, cand.hex)
        if current > ratio then
          choice, ratio = cand.hex, current
        end
      end
    end
    return choice, ratio
  end

  local neutrals = {}
  for _, cand in ipairs(candidates) do
    if cand.sat <= 0.2 then
      neutrals[#neutrals + 1] = cand
    end
  end

  local pool = #neutrals > 0 and neutrals or candidates
  local best, best_ratio = pick_from(pool)
  local target_ratio = target_text_contrast(base, candidates)

  if not best then
    best = "#ffffff"
    best_ratio = contrast_ratio(base, best)
  end

  if best_ratio < target_ratio then
    local white_ratio = contrast_ratio(base, "#ffffff")
    local black_ratio = contrast_ratio(base, "#000000")
    if white_ratio >= black_ratio then
      best = "#ffffff"
    else
      best = "#000000"
    end
  end

  return best
end

local function pick_crust_color(base, text, is_dark)
  if not base or not text then return base end
  local base_pos = RAMP.base or 0.079
  base_pos = math.max(0.01, math.min(base_pos, 0.99))
  local shift = base_pos / (1 - base_pos)
  if is_dark then
    return M.interpolate(base, text, -shift)
  end
  return M.interpolate(base, text, shift)
end

local function select_accent_candidates(candidates)
  local saturated = {}
  for _, cand in ipairs(candidates) do
    if cand.sat >= 0.2 then
      saturated[#saturated + 1] = cand
    end
  end
  if #saturated >= 6 then
    return saturated
  end
  return candidates
end

local function pick_accent_color(candidates, target_hue, used)
  local best, best_score
  for _, cand in ipairs(candidates) do
    if not used[cand.hex] then
      local score = hue_distance(cand.hue, target_hue) + (1 - cand.sat) * 40
      if not best or score < best_score then
        best, best_score = cand, score
      end
    end
  end

  if not best then
    for _, cand in ipairs(candidates) do
      local score = hue_distance(cand.hue, target_hue) + (1 - cand.sat) * 40
      if not best or score < best_score then
        best, best_score = cand, score
      end
    end
  end

  return best and best.hex or nil
end

--- Build a complete 26-colour Catppuccin palette.
---
--- When any colour data is available (LS_COLORS, OSC 4/11) the full
--- palette is derived via semantic mapping — no base flavour needed.
--- Returns nil only when there is zero data, so the caller can fall
--- back to a stock Catppuccin flavour.
---
--- @param terminal_colors table<number, string>  ANSI index → "#rrggbb" (from OSC 4)
--- @param ls_palette      table<string, string>  Catppuccin slot → "#rrggbb" (from LS_COLORS)
--- @param bg              string|nil             terminal background from OSC 11
--- @return table<string, string>|nil  slot → "#rrggbb", or nil when no data
function M.build(terminal_colors, ls_palette, bg)
  terminal_colors = terminal_colors or {}
  local has_terminal = not vim.tbl_isempty(terminal_colors)
  local has_ls = ls_palette and not vim.tbl_isempty(ls_palette)

  if not has_terminal and not has_ls and not bg then
    return nil
  end

  -- Detect dark / light
  local is_dark
  if bg then
    is_dark = M.detect_dark_light(bg) == "dark"
  else
    is_dark = vim.o.background ~= "light"
  end

  local candidates = collect_ansi_colors(terminal_colors)

  -- Base from terminal background or nearest ANSI endpoint
  local base = bg or pick_base_color(candidates, is_dark)
  if not base then
    local base_index = is_dark and 0 or 15
    base = terminal_colors[base_index] or DEFAULT_ANSI[base_index]
  end

  -- Text chosen by contrast against base
  local text = pick_text_color(base, candidates)
  if not text then
    text = is_dark and "#ffffff" or "#000000"
  end

  local crust = pick_crust_color(base, text, is_dark)

  local p = {
    base = base,
    text = text,
    crust = crust,
  }

  -- Build neutral ramp with base as anchor
  local base_pos = RAMP.base or 0.079
  base_pos = math.max(0.01, math.min(base_pos, 0.99))
  local upper_span = 1 - base_pos

  for slot, pos in pairs(RAMP) do
    if not p[slot] then
      if pos <= base_pos then
        p[slot] = M.interpolate(crust, base, pos / base_pos)
      else
        p[slot] = M.interpolate(base, text, (pos - base_pos) / upper_span)
      end
    end
  end

  -- Semantic accent mapping from ANSI colors
  local accent_candidates = select_accent_candidates(candidates)
  local used = {}
  for _, slot in ipairs(ACCENT_ORDER) do
    local hex = pick_accent_color(accent_candidates, ACCENT_TARGETS[slot], used)
    if hex then
      p[slot] = hex
      used[hex] = true
    end
  end

  -- LS_COLORS overrides only for accent slots
  for slot, hex in pairs(ls_palette or {}) do
    if ACCENT_SLOTS[slot] then
      p[slot] = hex
    end
  end

  -- Derived accents
  local maroon = p.maroon or p.red
  if maroon and p.text then
    p.rosewater = M.interpolate(maroon, p.text, 0.6)
  end
  if p.red and p.rosewater then
    p.flamingo = M.interpolate(p.red, p.rosewater, 0.5)
  end
  if p.blue and p.text then
    p.lavender = M.interpolate(p.blue, p.text, 0.4)
  end

  return p
end

return M
