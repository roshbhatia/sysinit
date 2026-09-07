vim.cmd.packadd("changes.nvim")

require("changes.notes").setup({
  provider = "git-notes",
  commit = "HEAD",
  origin = "user",
})
