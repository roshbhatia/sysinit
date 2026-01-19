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
  },
}
