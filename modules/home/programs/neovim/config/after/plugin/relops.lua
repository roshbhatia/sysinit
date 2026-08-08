if vim.g.RELOPS_ACTIVE == nil then
  vim.g.RELOPS_ACTIVE = true
end

local function refresh_line_numbers()
  if not vim.bo.modifiable or vim.bo.buftype ~= "" or vim.bo.filetype == "help" then
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    return
  end

  local mode = vim.api.nvim_get_mode().mode

  if vim.g.RELOPS_ACTIVE then
    local targeting_modes = {
      ["no"] = true, -- Operator-pending
      ["v"] = true, -- Visual
      ["V"] = true, -- Visual Line
      ["\22"] = true, -- Visual Block
      ["c"] = true, -- Command-line
    }
    vim.opt_local.relativenumber = targeting_modes[mode] or false
  else
    vim.opt_local.relativenumber = (mode ~= "i")
  end

  vim.opt_local.number = true
end

vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved", "BufEnter", "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("DynamicLineNumbers", { clear = true }),
  callback = refresh_line_numbers,
})

for i = 1, 9 do
  vim.keymap.set("n", tostring(i), function()
    if vim.g.RELOPS_ACTIVE then
      vim.opt_local.relativenumber = true
    end
    return tostring(i)
  end, { expr = true, silent = true })
end

vim.keymap.set("n", "<Esc>", function()
  vim.cmd.nohlsearch()
  if vim.g.RELOPS_ACTIVE then
    vim.opt_local.relativenumber = false
  end
  return "<Esc>"
end, { expr = true, silent = true, desc = "Clear search and reset RelOps" })
