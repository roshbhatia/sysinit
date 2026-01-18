return {
  {
    "olimorris/persisted.nvim",
    event = "BufReadPre",
    config = function()
      require("persisted").setup({
        use_git_branch = true,
        on_autoload_no_session = function()
          vim.cmd("Alpha")
        end,
      })
    end,
  },
}
