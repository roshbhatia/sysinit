local M = {}

local TRANSPARENT_TERMINALS = {
  kitty = true,
  alacritty = true,
  wezterm = true,
  ghostty = true,
  foot = true,
  contour = true,
  rio = true,
}

--- @return boolean
function M.is_transparent()
  if not vim.env.LS_COLORS or vim.env.LS_COLORS == "" then
    return false
  end

  if vim.env.KITTY_WINDOW_ID or vim.env.WEZTERM_PANE or vim.env.WT_SESSION then
    return true
  end

  local term_program = vim.env.TERM_PROGRAM

  if vim.env.TMUX then
    local handle = io.popen("tmux show-environment TERM_PROGRAM 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      local val = result:match("TERM_PROGRAM=(%S+)")
      if val then term_program = val end
    end
  end

  if term_program and TRANSPARENT_TERMINALS[term_program:lower()] then
    return true
  end

  local colorterm = vim.env.COLORTERM
  if colorterm == "truecolor" or colorterm == "24bit" then
    return true
  end

  local term = vim.env.TERM or ""
  if term:match("256color") or term:match("direct") then
    return true
  end

  return false
end

--- @param rgb_str string
--- @return string|nil
local function parse_osc_rgb(rgb_str)
  local r, g, b = rgb_str:match("rgb:(%x+)/(%x+)/(%x+)")
  if not r then return nil end

  local function to_byte(hex)
    if #hex >= 4 then return hex:sub(1, 2) end
    if #hex == 2 then return hex end
    if #hex == 1 then return hex .. hex end
    return "00"
  end

  return string.format("#%s%s%s", to_byte(r), to_byte(g), to_byte(b))
end

--- @param callback fun(colors: table<number, string>, bg: string|nil)
function M.query_colors(callback)
  local colors = {}
  local bg_color = nil

  if not vim.fn.has("gui_running") and vim.fn.has("nvim") == 1 and #vim.api.nvim_list_uis() == 0 then
    vim.schedule(function() callback(colors, bg_color) end)
    return
  end

  local fd, open_err = vim.uv.fs_open("/dev/tty", "r+", 438) -- 0o666
  if not fd then
    vim.schedule(function() callback(colors, bg_color) end)
    return
  end

  local ok, tty = pcall(vim.uv.new_tty, fd, true)
  if not ok or not tty then
    vim.uv.fs_close(fd)
    vim.schedule(function() callback(colors, bg_color) end)
    return
  end

  local response_buf = ""
  local timer = vim.uv.new_timer()
  local done = false

  local function finish()
    if done then return end
    done = true

    if timer then
      timer:stop()
      timer:close()
    end
    pcall(function() tty:read_stop() end)
    pcall(function() tty:close() end)

    local buf = response_buf:gsub("\27\27", "\27")

    for idx, rgb in buf:gmatch("\27%]4;(%d+);(rgb:%x+/%x+/%x+)") do
      local hex = parse_osc_rgb(rgb)
      if hex then colors[tonumber(idx)] = hex end
    end

    local bg_rgb = buf:match("\27%]11;(rgb:%x+/%x+/%x+)")
    if bg_rgb then bg_color = parse_osc_rgb(bg_rgb) end

    vim.schedule(function() callback(colors, bg_color) end)
  end

  tty:read_start(function(err, data)
    if err or not data then return end
    response_buf = response_buf .. data
  end)

  local in_tmux = vim.env.TMUX ~= nil
  local parts = {}

  for i = 0, 15 do
    if in_tmux then
      parts[#parts + 1] = string.format("\27Ptmux;\27\27]4;%d;?\7\27\\", i)
    else
      parts[#parts + 1] = string.format("\27]4;%d;?\7", i)
    end
  end

  if in_tmux then
    parts[#parts + 1] = "\27Ptmux;\27\27]11;?\7\27\\"
  else
    parts[#parts + 1] = "\27]11;?\7"
  end

  tty:write(table.concat(parts))

  timer:start(200, 0, function()
    finish()
  end)
end

return M
