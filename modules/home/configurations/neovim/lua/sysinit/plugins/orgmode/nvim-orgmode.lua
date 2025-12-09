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
          "<leader>or",
          function()
            orgmode.refile_heading()
          end,
          desc = "Org: Refile heading",
        },
        {
          "<leader>oh",
          function()
            orgmode.search_headings()
          end,
          desc = "Org: Search headings",
        },
        {
          "<leader>oi",
          function()
            orgmode.insert_link()
          end,
          desc = "Org: Insert link",
        },
      }
    end,
  },
  {
    "chipsenkbeil/org-roam.nvim",
    lazy = true,
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("org-roam").setup({
        directory = "~/org/roam",
        org_files = {
          "~/org/roam/**/*.org",
        },
      })
    end,
    keys = function()
      return {
        {
          "<leader>nf",
          function()
            require("org-roam").node_find()
          end,
          desc = "Roam: Find node",
        },
        {
          "<leader>ni",
          function()
            require("org-roam").node_insert()
          end,
          desc = "Roam: Insert node link",
          mode = { "n", "i" },
        },
        {
          "<leader>nc",
          function()
            require("org-roam").capture()
          end,
          desc = "Roam: Capture",
        },
        {
          "<leader>nb",
          function()
            require("org-roam").toggle_roam_buffer()
          end,
          desc = "Roam: Backlinks",
        },
      }
    end,
  },
  {
    "hamidi-dev/org-super-agenda.nvim",
    lazy = true,
    dependencies = {
      "nvim-orgmode/orgmode",
      { "lukas-reineke/headlines.nvim", config = true },
    },
    config = function()
      require("org-super-agenda").setup({
        org_directories = { "~/org/notes" },

        todo_states = {
          {
            name = "TODO",
            keymap = "ot",
            color = "#FF5555",
            strike_through = false,
            fields = { "todo", "headline", "priority", "tags" },
          },
          {
            name = "IN PROGRESS",
            shortcut = "p",
            keymap = "op",
            color = "#FFAA00",
            strike_through = false,
            fields = { "todo", "headline", "priority", "tags" },
          },
          {
            name = "DONE",
            keymap = "od",
            color = "#50FA7B",
            strike_through = true,
            fields = { "todo", "headline", "priority", "tags" },
          },
        },

        keymaps = {
          filter_reset = "oa",
          filter = "of",
          filter_fuzzy = "oz",
          undo = "u",
          cycle_todo = "t",
          set_state = "s",
          reload = "r",
          refile = "R",
          hide_item = "x",
          preview = "K",
          reset_hidden = "X",
          cycle_view = "ov",
        },

        window = {
          width = 0.85,
          height = 0.85,
          border = "rounded",
          title = "Kanban",
          title_pos = "center",
        },

        groups = {
          {
            name = "📋 TODO",
            matcher = function(i)
              return i.todo_state == "TODO"
            end,
            sort = { by = "priority", order = "desc" },
          },
          {
            name = "⚡ IN PROGRESS",
            matcher = function(i)
              return i.todo_state == "IN PROGRESS"
            end,
            sort = { by = "priority", order = "desc" },
          },
          {
            name = "✅ DONE",
            matcher = function(i)
              return i.todo_state == "DONE"
            end,
            sort = { by = "priority", order = "desc" },
          },
        },

        hide_empty_groups = false,
        allow_duplicates = false,
        group_format = "* %s",
        show_other_group = false,
        show_tags = true,
        show_filename = false,
        heading_max_length = 80,
        persist_hidden = false,
        view_mode = "classic",

        classic = {
          heading_order = { "todo", "priority", "headline" },
          short_date_labels = false,
          inline_dates = true,
        },

        group_sort = { by = "priority", order = "desc" },
        debug = false,
      })
    end,
    keys = function()
      return {
        {
          "<leader>oa",
          "<cmd>OrgSuperAgenda<cr>",
          desc = "Org: Kanban",
        },
      }
    end,
  },
}

return M
