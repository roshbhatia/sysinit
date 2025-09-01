local M = {}

M.plugins = {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged_enable = true,
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          follow_files = true,
        },
        auto_attach = true,
        attach_to_untracked = false,
        current_line_blame = false,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 1000,
          ignore_whitespace = false,
          virt_text_priority = 100,
          use_focus = true,
        },
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
      })
    end,
    keys = function()
      return {
        {
          "]c",
          function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              require("gitsigns").nav_hunk("next")
            end
          end,
          desc = "Next git hunk",
          mode = "n",
        },
        {
          "[c",
          function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              require("gitsigns").nav_hunk("prev")
            end
          end,
          desc = "Previous git hunk",
          mode = "n",
        },
        {
          "<leader>ghs",
          function()
            require("gitsigns").stage_hunk()
          end,
          desc = "Git hunk stage",
          mode = "n",
        },
        {
          "<leader>ghs",
          function()
            require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Git hunk stage (visual)",
          mode = "v",
        },
        {
          "<leader>ghr",
          function()
            require("gitsigns").reset_hunk()
          end,
          desc = "Git hunk reset",
          mode = "n",
        },
        {
          "<leader>ghr",
          function()
            require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Git hunk reset (visual)",
          mode = "v",
        },
        {
          "<leader>ghS",
          function()
            require("gitsigns").stage_buffer()
          end,
          desc = "Git hunk stage buffer",
          mode = "n",
        },
        {
          "<leader>ghR",
          function()
            require("gitsigns").reset_buffer()
          end,
          desc = "Git hunk reset buffer",
          mode = "n",
        },
        {
          "<leader>ghu",
          function()
            require("gitsigns").undo_stage_hunk()
          end,
          desc = "Git hunk undo stage",
          mode = "n",
        },
        {
          "<leader>ghp",
          function()
            require("gitsigns").preview_hunk()
          end,
          desc = "Git hunk preview popup",
          mode = "n",
        },
        {
          "<leader>ghi",
          function()
            require("gitsigns").preview_hunk_inline()
          end,
          desc = "Git hunk inline preview",
          mode = "n",
        },
        {
          "<leader>gbl",
          function()
            require("gitsigns").blame_line({ full = true })
          end,
          desc = "Git blame line popup",
          mode = "n",
        },
        {
          "<leader>gbt",
          function()
            require("gitsigns").toggle_current_line_blame()
          end,
          desc = "Git blame toggle",
          mode = "n",
        },
        {
          "<leader>gdf",
          function()
            require("gitsigns").diffthis()
          end,
          desc = "Git diff vs index",
          mode = "n",
        },
        {
          "<leader>gdh",
          function()
            require("gitsigns").diffthis("~")
          end,
          desc = "Git diff vs HEAD",
          mode = "n",
        },

        -- Quickfix integration
        {
          "<leader>gql",
          function()
            require("gitsigns").setqflist()
          end,
          desc = "Git quickfix list hunks",
          mode = "n",
        },
        {
          "<leader>gqa",
          function()
            require("gitsigns").setqflist("all")
          end,
          desc = "Git quickfix all hunks",
          mode = "n",
        },

        -- Toggles
        {
          "<leader>gts",
          function()
            require("gitsigns").toggle_signs()
          end,
          desc = "Git toggle signs",
          mode = "n",
        },
        {
          "<leader>gtw",
          function()
            require("gitsigns").toggle_word_diff()
          end,
          desc = "Git toggle word diff",
          mode = "n",
        },
        {
          "<leader>gtn",
          function()
            require("gitsigns").toggle_numhl()
          end,
          desc = "Git toggle number highlight",
          mode = "n",
        },
        {
          "<leader>gtl",
          function()
            require("gitsigns").toggle_linehl()
          end,
          desc = "Git toggle line highlight",
          mode = "n",
        },

        -- Text object
        {
          "ih",
          function()
            require("gitsigns").select_hunk()
          end,
          desc = "Select hunk (text object)",
          mode = { "o", "x" },
        },
      }
    end,
  },
}

return M
