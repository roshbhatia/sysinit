-- pulled heavily from https://github.com/yaocccc/nvim-foldsign
local M = {}

-- Configuration
local config = {
  offset = -3,
  foldsigns = {
    close = "-",
    open = "*",
    seps = { "│", "┃" },
  },
}

local ns
local numberwidth

local function should_display_foldsign()
  -- Skip floating windows
  local win_config = vim.api.nvim_win_get_config(0)
  if win_config.relative ~= "" then
    return false
  end

  -- Skip special buffer types
  if vim.bo.buftype ~= "" then
    return false
  end

  -- Skip buffers without a real file
  if vim.api.nvim_buf_get_name(0) == "" then
    return false
  end

  -- Only show if treesitter is enabled
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  return ok and parser ~= nil
end

local function setsign(line, sign)
  vim.api.nvim_buf_set_extmark(0, ns, line, 0, {
    virt_text_win_col = config.offset - numberwidth,
    virt_text = { { sign, "FoldColumn" } },
  })
end

function M.foldsign()
  if not should_display_foldsign() then
    return
  end

  local topline = vim.fn.line("w0") - 1
  local botline = vim.fn.line("w$")
  vim.api.nvim_buf_clear_namespace(0, ns, topline, botline)

  numberwidth = #tostring(vim.fn.line("$"))
  if numberwidth < vim.o.numberwidth - 1 then
    numberwidth = vim.o.numberwidth - 1
  end

  local pre = 0
  for i = topline, botline do
    local foldlevel = vim.fn.foldlevel(i)
    if foldlevel > 0 then
      local foldtext = " "
      local foldclosed = vim.fn.foldclosed(i)
      if foldclosed > 0 and i == foldclosed then
        foldtext = config.foldsigns.close
      elseif foldlevel > pre then
        foldtext = config.foldsigns.open
      else
        foldtext = config.foldsigns.seps[foldlevel] or config.foldsigns.seps[#config.foldsigns.seps]
      end
      setsign(i - 1, foldtext)
    end
    pre = foldlevel
  end
end

function M.setup(opt)
  vim.opt.foldenable = true
  vim.opt.foldlevel = 99
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  vim.opt.fillchars:append({ fold = " " })

  ns = vim.api.nvim_create_namespace("foldsign")

  -- Apply user config overrides
  if opt and opt.foldsigns then
    config.foldsigns = opt.foldsigns
  end
  if opt and opt.offset ~= nil then
    config.offset = opt.offset
  end

  local folding = require("folding")
  vim.cmd('au VimEnter,WinEnter,BufWinEnter,ModeChanged,CursorMoved,CursorHold * lua require("folding").foldsign()')
end

return M
