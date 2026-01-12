local M = {}

M.plugins = {
  {
    "nvim-orgmode/orgmode",
    lazy = false,
    priority = 1000,
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/org/notes/**/*" },
        org_default_notes_file = "~/org/notes/kanban.org",
        mappings = {
          disable_all = false,
        },
      })
    end,
  },
  {
    "nvim-orgmode/telescope-orgmode.nvim",
    lazy = true,
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("orgmode")
    end,
    keys = function()
      local orgmode = require("telescope").extensions.orgmode
      return {
        {
          "<localleader>r",
          function()
            orgmode.refile_heading()
          end,
          desc = "Refile heading",
          ft = "org",
        },
        {
          "<localleader>h",
          function()
            orgmode.search_headings()
          end,
          desc = "Search headings",
          ft = "org",
        },
        {
          "<localleader>i",
          function()
            orgmode.insert_link()
          end,
          desc = "Insert link",
          ft = "org",
        },
      }
    end,
  },
}

return M
