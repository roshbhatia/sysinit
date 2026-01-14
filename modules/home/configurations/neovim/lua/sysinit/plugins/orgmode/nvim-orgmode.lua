local M = {}

M.plugins = {
  {
    "nvim-orgmode/orgmode",
    lazy = false,
    priority = 1000,
    ft = {
      "org",
    },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/org/notes/**/*" },
        org_default_notes_file = "~/org/notes/kanban.org",
      })
    end,
  },
}

return M
