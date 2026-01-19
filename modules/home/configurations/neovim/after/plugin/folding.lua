local config = {
  offset = -3,
  foldsigns = {
    close = "-",
    open = "*",
    seps = { "│", "┃" },
  },
}

local ns = vim.api.nvim_create_namespace("foldsign")

vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.fillchars:append({ fold = " " })

local function should_display_foldsign()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    return false
  end
  if vim.bo.buftype ~= "" then
    return false
  end
  if vim.api.nvim_buf_get_name(0) == "" then
    return false
  end

  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  return ok and parser ~= nil
end

local function update_foldsign()
  if not should_display_foldsign() then
    return
  end

  local topline = vim.fn.line("w0") - 1
  local botline = vim.fn.line("w$")

  if not vim.api.nvim_buf_is_valid(0) then
    return
  end
  vim.api.nvim_buf_clear_namespace(0, ns, topline, botline)

  local numberwidth = #tostring(vim.fn.line("$"))
  local min_width = vim.o.numberwidth - 1
  if numberwidth < min_width then
    numberwidth = min_width
  end

  local pre = 0
  for i = topline + 1, botline do
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

      vim.api.nvim_buf_set_extmark(0, ns, i - 1, 0, {
        virt_text_win_col = config.offset - numberwidth,
        virt_text = { { foldtext, "FoldColumn" } },
      })
    end
    pre = foldlevel
  end
end

local group = vim.api.nvim_create_augroup("FoldSignGroup", { clear = true })

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = group,
  callback = function()
    if should_display_foldsign() then
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter", "ModeChanged", "CursorMoved", "CursorHold" }, {
  group = group,
  callback = function()
    update_foldsign()
  end,
})
