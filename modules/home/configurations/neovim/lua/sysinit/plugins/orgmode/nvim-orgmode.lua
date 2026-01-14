local M = {}

M.plugins = {
  {
    "nvim-orgmode/orgmode",
    ft = {
      "org",
    },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/org/notes/**/*" },
        org_default_notes_file = "~/org/notes/kanban.org",
        win_border = "rounded",
      })
    end,
  },
}

return M
