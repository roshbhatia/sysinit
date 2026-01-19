return {
  "rmagatti/auto-session",
  lazy = false,
  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    close_filetypes_on_save = {
      "alpha",
      "checkhealth",
      "neo-tree",
    },
    git_use_branch_name = true,
    show_auto_restore_notif = true,
    no_restore_cmds = {
      function()
        if vim.fn.argc(-1) == 0 then
          vim.cmd("Alpha")
        end
      end,
    },
  },
}
