return {
  {
    "rmagatti/auto-session",
    config = function()
      require("auto-session").setup({
        log_level = "error",
        auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        auto_session_enable_last_session = false,
        auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        auto_session_use_git_branch = true,
        pre_save_cmds = { "NvimTreeClose" },
      })

      -- Keybindings for session management
      vim.keymap.set("n", "<leader>ss", require("auto-session.session-lens").search_session, { desc = "Search Sessions" })
      vim.keymap.set("n", "<leader>sd", require("auto-session").DeleteSession, { desc = "Delete Session" })
    end,
  },
}
