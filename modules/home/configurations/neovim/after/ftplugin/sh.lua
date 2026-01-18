-- Shell script (bash/zsh) specific settings and keymaps

-- Formatting
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Keymaps
local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Make script executable
map("n", "<localleader>sx", function()
  local file = vim.fn.expand("%:p")
  vim.fn.system(string.format("chmod +x %s", vim.fn.shellescape(file)))
  vim.notify("Made executable: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
end, vim.tbl_extend("force", opts, { desc = "Shell: Make executable" }))

-- Run current script
map("n", "<localleader>sr", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | term " .. vim.fn.shellescape(file))
end, vim.tbl_extend("force", opts, { desc = "Shell: Run script" }))

-- Insert shebang if missing
local function ensure_shebang()
  local first_line = vim.fn.getline(1)
  if not first_line:match("^#!") then
    local shell = vim.bo.filetype == "zsh" and "zsh" or "bash"
    vim.fn.append(0, "#!/usr/bin/env " .. shell)
    vim.fn.append(1, "")
    vim.cmd("write")
  end
end

-- Auto-add shebang for new files
vim.api.nvim_create_autocmd("BufNewFile", {
  buffer = 0,
  callback = ensure_shebang,
})
