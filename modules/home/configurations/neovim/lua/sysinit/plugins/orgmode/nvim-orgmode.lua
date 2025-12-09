local M = {}

M.plugins = {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = "~/org/**/*",
        org_default_notes_file = "~/orgfiles/kanban.org",
      })
    end,
  },
}

return M
