vim.opt_local.expandtab = true

Snacks.keymap.set("n", "<localleader>x", function()
  local file = vim.fn.expand("%:p")
  vim.fn.system(string.format("chmod +x %s", vim.fn.shellescape(file)))
  vim.notify("Made executable: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
end, { ft = "sh", desc = "Make executable" })

Snacks.keymap.set("n", "<localleader>r", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("split | term " .. vim.fn.shellescape(file))
end, { ft = "sh", desc = "Run script" })

local function ensure_shebang()
  local first_line = vim.fn.getline(1)
  if not first_line:match("^#!") then
    local shell = vim.bo.filetype == "zsh" and "zsh" or "bash"
    vim.fn.append(0, "#!/usr/bin/env " .. shell)
    vim.fn.append(1, "")
    vim.cmd("write")
  end
end

vim.api.nvim_create_autocmd("BufNewFile", {
  buffer = 0,
  callback = ensure_shebang,
})
