return {
  "rmagatti/auto-session",
  lazy = false,
  opts = {
    auto_save = true,
    auto_restore = true,
    auto_create = true,
    suppressed_dirs = { "~/", "~/Downloads", "/" },
    close_unsupported_windows = true,
    close_filetypes_on_save = {
      "snacks_dashboard",
      "checkhealth",
      "neo-tree",
    },
    git_use_branch_name = true,
    bypass_save_filetypes = { "snacks_dashboard" },
    args_allow_single_directory = true,
    cwd_change_handling = true,
    continue_restore_on_error = true,
    log_level = "info",
    -- A diff review is a view over the working tree, not a layout to restore. Saved,
    -- its tab comes back empty, and one accumulated per review: five consecutive
    -- reviews of one workspace started with 2, 3, 4, 5, then 6 tabs. Closing it here
    -- rather than on `VimLeavePre` is what makes it happen before the save, since
    -- autocommands run in registration order and this plugin registers first.
    pre_save_cmds = {
      function()
        pcall(function()
          require("harness.api").review_close()
        end)
      end,
    },
    post_restore_cmds = {
      function()
        if vim.fn.argc(-1) == 0 and #vim.fn.getbufinfo({ buflisted = 1 }) == 0 then
          Snacks.dashboard.open({
            wo = {
              cursorline = true,
            },
          })
        end
      end,
    },
    no_restore_cmds = {
      function()
        if vim.fn.argc(-1) == 0 then
          Snacks.dashboard.open({
            wo = {
              cursorline = true,
            },
          })
        end
      end,
    },
  },
}
