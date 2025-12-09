local M = {}

M.plugins = {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = "~/org/**/*",
        org_default_notes_file = "~/org/kanban.org",
      })
    end,
  },
  {
    "nvim-orgmode/telescope-orgmode.nvim",
    event = "VeryLazy",
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
          "<leader>r",
          function()
            orgmode.refile_heading()
          end,
          desc = "Org: Refile heading",
        },
        {
          "<leader>foh",
          function()
            orgmode.search_headings()
          end,
          desc = "Org: Search headings",
        },
        {
          "<leader>foi",
          function()
            orgmode.insert_link()
          end,
          desc = "Org: Insert link",
        },
        {
          "<leader>fot",
          function()
            orgmode.search_tags()
          end,
          desc = "Org: Search tags",
        },
      }
    end,
  },
  {
    "chipsenkbeil/org-roam.nvim",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("org-roam").setup({
        directory = "~/org/roam",
        org_files = {
          "~/org/roam/*.org",
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
          desc = "Roam: Capture new node",
        },
        {
          "<leader>nb",
          function()
            require("org-roam").toggle_roam_buffer()
          end,
          desc = "Roam: Toggle backlinks buffer",
        },
        {
          "<leader>nd",
          function()
            require("org-roam").goto_today()
          end,
          desc = "Roam: Go to daily note",
        },
        {
          "<leader>nD",
          function()
            require("org-roam").goto_date()
          end,
          desc = "Roam: Go to date",
        },
        {
          "<leader>ng",
          function()
            require("org-roam").sync()
          end,
          desc = "Roam: Sync database",
        },
      }
    end,
  },
  {
    "hamidi-dev/org-super-agenda.nvim",
    dependencies = {
      "nvim-orgmode/orgmode",
      { "lukas-reineke/headlines.nvim", config = true },
    },
    config = function()
      require("org-super-agenda").setup({
        org_directories = { "~/org" },
        exclude_files = {},
        exclude_directories = {},

        todo_states = {
          {
            name = "TODO",
            keymap = "ot",
            color = "#FF5555",
            strike_through = false,
            fields = { "filename", "todo", "headline", "priority", "date", "tags" },
          },
          {
            name = "IN PROGRESS",
            shortcut = "p",
            keymap = "op",
            color = "#FFAA00",
            strike_through = false,
            fields = { "filename", "todo", "headline", "priority", "date", "tags" },
          },
          {
            name = "DONE",
            keymap = "od",
            color = "#50FA7B",
            strike_through = true,
            fields = { "filename", "todo", "headline", "priority", "date", "tags" },
          },
        },

        keymaps = {
          filter_reset = "oa",
          toggle_other = "oo",
          filter = "of",
          filter_fuzzy = "oz",
          filter_query = "oq",
          undo = "u",
          reschedule = "cs",
          set_deadline = "cd",
          cycle_todo = "t",
          set_state = "s",
          reload = "r",
          refile = "R",
          hide_item = "x",
          preview = "K",
          reset_hidden = "X",
          toggle_duplicates = "D",
          cycle_view = "ov",
        },

        window = {
          width = 0.9,
          height = 0.9,
          border = "rounded",
          title = "Kanban Board",
          title_pos = "center",
          margin_left = 0,
          margin_right = 0,
          fullscreen_border = "none",
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

        upcoming_days = 10,
        hide_empty_groups = false,
        keep_order = false,
        allow_duplicates = false,
        group_format = "* %s",
        other_group_name = "Other",
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
        compact = {
          filename_min_width = 10,
          label_min_width = 12,
        },

        group_sort = { by = "priority", order = "desc" },

        popup_mode = {
          enabled = false,
          hide_command = nil,
        },

        debug = false,
      })
    end,
    keys = function()
      return {
        {
          "<leader>oa",
          "<cmd>OrgSuperAgenda<cr>",
          desc = "Org: Kanban board",
        },
        {
          "<leader>oA",
          "<cmd>OrgSuperAgenda!<cr>",
          desc = "Org: Kanban board (fullscreen)",
        },
      }
    end,
  },
}

return M
