-- YARA filetype settings

-- Indentation: 4-space tabs (YARA convention)
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

-- Comments (YARA uses // and /* */)
vim.opt_local.commentstring = "// %s"
vim.opt_local.comments = "://,s1:/*,mb:*,ex:*/"

-- Compiler/makeprg for syntax checking
vim.opt_local.makeprg = "yr check %"
vim.opt_local.errorformat = "error: %m"

-- Keymaps for yara-x commands
Snacks.keymap.set("n", "<localleader>c", function()
  vim.cmd("make")
end, { ft = "yara", desc = "Check rule syntax" })

Snacks.keymap.set("n", "<localleader>f", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("!yr fmt " .. vim.fn.shellescape(file))
  vim.cmd("edit!")
end, { ft = "yara", desc = "Format with yr fmt" })

Snacks.keymap.set("n", "<localleader>F", function()
  local file = vim.fn.expand("%:p")
  vim.cmd("!yr fix warnings " .. vim.fn.shellescape(file))
  vim.cmd("edit!")
end, { ft = "yara", desc = "Fix warnings" })

Snacks.keymap.set("n", "<localleader>C", function()
  local file = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r") .. ".yarc"
  vim.cmd("split | term yr compile -o " .. vim.fn.shellescape(output) .. " " .. vim.fn.shellescape(file))
end, { ft = "yara", desc = "Compile to binary" })
