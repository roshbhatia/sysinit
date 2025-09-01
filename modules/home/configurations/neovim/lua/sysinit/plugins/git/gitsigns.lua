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
          desc = "Stage hunk",
          mode = "n",
        },
        {
          "<leader>ghs",
          function()
            require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Stage hunk (visual)",
          mode = "v",
        },
        {
          "<leader>ghr",
          function()
            require("gitsigns").reset_hunk()
          end,
          desc = "Reset hunk",
          mode = "n",
        },
        {
          "<leader>ghr",
          function()
            require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Reset hunk (visual)",
          mode = "v",
        },
        {
          "<leader>ghS",
          function()
            require("gitsigns").stage_buffer()
          end,
          desc = "Stage buffer",
          mode = "n",
        },
        {
          "<leader>ghR",
          function()
            require("gitsigns").reset_buffer()
          end,
          desc = "Reset buffer",
          mode = "n",
        },
        {
          "<leader>ghu",
          function()
            require("gitsigns").undo_stage_hunk()
          end,
          desc = "Undo stage hunk",
          mode = "n",
        },
        {
          "<leader>ghp",
          function()
            require("gitsigns").preview_hunk()
          end,
          desc = "Preview hunk (popup)",
          mode = "n",
        },
        {
          "<leader>ghi",
          function()
            require("gitsigns").preview_hunk_inline()
          end,
          desc = "Preview hunk (inline)",
          mode = "n",
        },
        {
          "<leader>gbl",
          function()
            require("gitsigns").blame_line({ full = true })
          end,
          desc = "Blame line (popup)",
          mode = "n",
        },
        {
          "<leader>gbt",
          function()
            require("gitsigns").toggle_current_line_blame()
          end,
          desc = "Toggle line blame",
          mode = "n",
        },
        {
          "<leader>gdf",
          function()
            require("gitsigns").diffthis()
          end,
          desc = "Diff this (index)",
          mode = "n",
        },
        {
          "<leader>gdh",
          function()
            require("gitsigns").diffthis("~")
          end,
          desc = "Diff this (HEAD)",
          mode = "n",
        },

        -- Quickfix integration
        {
          "<leader>gql",
          function()
            require("gitsigns").setqflist()
          end,
          desc = "Quickfix list (hunks)",
          mode = "n",
        },
        {
          "<leader>gqa",
          function()
            require("gitsigns").setqflist("all")
          end,
          desc = "Quickfix list (all hunks)",
          mode = "n",
        },
        {
          "<leader>gts",
          function()
            require("gitsigns").toggle_signs()
          end,
          desc = "Toggle signs",
          mode = "n",
        },
        {
          "<leader>gtw",
          function()
            require("gitsigns").toggle_word_diff()
          end,
          desc = "Toggle word diff",
          mode = "n",
        },
        {
          "<leader>gtn",
          function()
            require("gitsigns").toggle_numhl()
          end,
          desc = "Toggle number highlight",
          mode = "n",
        },
        {
          "<leader>gtl",
          function()
            require("gitsigns").toggle_linehl()
          end,
          desc = "Toggle line highlight",
          mode = "n",
        },
        {
          "ih",
          function()
            require("gitsigns").select_hunk()
          end,
          desc = "Select hunk",
          mode = { "o", "x" },
        },
      }
    end,
  },
}

return M
