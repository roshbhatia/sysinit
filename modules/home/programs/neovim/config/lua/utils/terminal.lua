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

function M.is_transparent()
  if not vim.env.LS_COLORS or vim.env.LS_COLORS == "" then
    return false
  end

  if vim.env.KITTY_WINDOW_ID or vim.env.WEZTERM_PANE or vim.env.WT_SESSION then
    return true
  end

  local term_program = vim.env.TERM_PROGRAM

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

local function parse_osc_rgb(rgb_str)
  local r, g, b = rgb_str:match("rgb:(%x+)/(%x+)/(%x+)")
  if not r then
    return nil
  end

  local function to_byte(hex)
    if #hex >= 4 then
      return hex:sub(1, 2)
    end
    if #hex == 2 then
      return hex
    end
    if #hex == 1 then
      return hex .. hex
    end
    return "00"
  end

  return string.format("#%s%s%s", to_byte(r), to_byte(g), to_byte(b))
end

-- Use TermResponse because Nvim owns and consumes terminal replies.
function M.query_colors(callback)
  local colors = {}
  local bg_color = nil
  local selection = nil

  if #vim.api.nvim_list_uis() == 0 then
    vim.schedule(function()
      callback(colors, bg_color, selection)
    end)
    return
  end

  local done = false
  local timer = assert(vim.uv.new_timer())
  local autocmd_id

  local function finish()
    if done then
      return
    end
    done = true

    timer:stop()
    timer:close()
    pcall(vim.api.nvim_del_autocmd, autocmd_id)

    vim.schedule(function()
      callback(colors, bg_color, selection)
    end)
  end

  local function set_selection(key, hex)
    selection = selection or {}
    selection[key] = hex
  end

  autocmd_id = vim.api.nvim_create_autocmd("TermResponse", {
    nested = true,
    callback = function(ev)
      local resp = type(ev.data) == "table" and ev.data.sequence or ev.data
      if type(resp) ~= "string" then
        return
      end

      local idx, rgb = resp:match("\27%]4;(%d+);(rgb:%x+/%x+/%x+)")
      if idx then
        local hex = parse_osc_rgb(rgb)
        if hex then
          colors[tonumber(idx)] = hex
        end
        return
      end

      local bg_rgb = resp:match("\27%]11;(rgb:%x+/%x+/%x+)")
      if bg_rgb then
        bg_color = parse_osc_rgb(bg_rgb)
        return
      end

      local sel_bg = resp:match("\27%]17;(rgb:%x+/%x+/%x+)")
      if sel_bg then
        set_selection("bg", parse_osc_rgb(sel_bg))
        return
      end

      local sel_fg = resp:match("\27%]19;(rgb:%x+/%x+/%x+)")
      if sel_fg then
        set_selection("fg", parse_osc_rgb(sel_fg))
      end
    end,
  })

  local parts = {}

  for i = 0, 15 do
    parts[#parts + 1] = string.format("\27]4;%d;?\27\\", i)
  end

  parts[#parts + 1] = "\27]11;?\27\\"
  -- Use OSC 17 and 19 because ANSI ramp slots vary across schemes.
  parts[#parts + 1] = "\27]17;?\27\\"
  parts[#parts + 1] = "\27]19;?\27\\"

  vim.api.nvim_ui_send(table.concat(parts))

  timer:start(300, 0, function()
    vim.schedule(finish)
  end)
end

return M
