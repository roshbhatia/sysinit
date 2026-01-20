return {
  "rmagatti/auto-session",
  lazy = false,
  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
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
    continue_restore_on_error = true,
    log_level = "info",
    post_restore_cmds = {
      function()
        -- Open dashboard if no files were restored
        if vim.fn.argc(-1) == 0 and #vim.fn.getbufinfo({ buflisted = 1 }) == 0 then
          Snacks.dashboard.open()
        end
      end,
    },
    no_restore_cmds = {
      function()
        -- Open dashboard when starting without arguments and no session to restore
        if vim.fn.argc(-1) == 0 then
          Snacks.dashboard.open()
        end
      end,
    },
  },
}
