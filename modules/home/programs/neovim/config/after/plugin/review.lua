-- The review's keys. Not a plugin spec, because the review is this config's own code and
-- `lua/review` is already on the runtimepath.
local function review()
  return require("review")
end

Snacks.keymap.set("n", "<leader>dr", function()
  review().toggle()
end, { desc = "Toggle the review" })

Snacks.keymap.set("n", "<leader>dt", function()
  review().toggle_placement()
end, { desc = "Review spine: bottom or tree" })

Snacks.keymap.set("n", "<leader>dl", function()
  review().toggle_layout()
end, { desc = "Review file view: split or inline" })

Snacks.keymap.set("n", "<leader>dR", function()
  review().refresh()
end, { desc = "Reload the review" })

Snacks.keymap.set("n", "<leader>db", function()
  vim.ui.input({ prompt = "Compare the working tree back to: " }, function(base)
    if base ~= nil then
      review().set_base(base)
    end
  end)
end, { desc = "Set the review's base commit" })

-- `q` closes the review from any window of its tab. Set per buffer as that buffer is
-- shown, because the review's windows hold ordinary file buffers and a global `q` would
-- take the key everywhere.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("review_quit", { clear = true }),
  callback = function(args)
    local ok, mod = pcall(require, "review")
    if not ok or not mod.here() then
      return
    end
    -- Not the quickfix window, where `q` already closes the list and where taking the
    -- key would cost the reader that.
    if vim.bo[args.buf].filetype == "qf" then
      return
    end
    vim.keymap.set("n", "q", function()
      require("review").close()
    end, { buffer = args.buf, desc = "Close the review" })
  end,
})
