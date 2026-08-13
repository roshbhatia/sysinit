vim.opt_local.number = false
vim.opt_local.wrap = false
vim.opt_local.spell = false
vim.opt_local.cursorline = true

Snacks.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, desc = "Close" })

-- Scheduled, because `nvim-bqf` sets its own buffer-local `<CR>` from a `FileType qf`
-- autocmd that runs after this file, and the last map set is the one that answers.
local buf = vim.api.nvim_get_current_buf()
vim.schedule(function()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  Snacks.keymap.set("n", "<CR>", function()
    local ok, scopes = pcall(require, "harness.scopes")
    if ok and scopes.activate() then
      return
    end
    -- What bqf's own map calls, so a file entry opens the way it does everywhere else.
    if not pcall(function()
      require("bqf.qfwin.handler").open(false)
    end) then
      vim.cmd(".cc")
    end
  end, { buffer = buf, desc = "Open entry, or switch the review scope" })
end)
