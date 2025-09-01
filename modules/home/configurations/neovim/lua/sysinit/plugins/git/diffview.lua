local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
        signs = {
          fold_closed = "▶",
          fold_open = "▼",
          done = "✓",
        },
        file_panel = {
          listing_style = "list",
          win_config = {
            position = "bottom",
            height = 25,
          },
        },
        file_history_panel = {
          win_config = {
            position = "bottom",
            height = 10,
          },
        },
        keymaps = {
          disable_defaults = false,
          view = {
            {
              "n",
              "q",
              "<cmd>DiffviewClose<cr>",
              { desc = "Close diffview" },
            },
            {
              "n",
              "<esc>",
              "<cmd>DiffviewClose<cr>",
              { desc = "Close diffview" },
            },
          },
          file_panel = {
            {
              "n",
              "q",
              "<cmd>DiffviewClose<cr>",
              { desc = "Close diffview" },
            },
            {
              "n",
              "<esc>",
              "<cmd>DiffviewClose<cr>",
              { desc = "Close diffview" },
            },
            {
              "n",
              "<leader>b",
              false,
            },
            {
              "n",
              "<leader>e",
              false,
            },
          },
          file_history_panel = {
            {
              "n",
              "q",
              "<cmd>DiffviewClose<cr>",
              { desc = "Close diffview" },
            },
            {
              "n",
              "<esc>",
              "<cmd>DiffviewClose<cr>",
              { desc = "Close diffview" },
            },
            {
              "n",
              "<leader>b",
              false,
            },
            {
              "n",
              "<leader>e",
              false,
            },
          },
        },
      })
    end,
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = function()
      local function is_diffview_open()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local ft = vim.api.nvim_buf_get_option(buf, "filetype")
            if ft == "DiffviewFiles" or ft == "DiffviewFileHistory" then
              return true
            end
          end
        end
        return false
      end

      return {
        {
          "<leader>gd",
          function()
            if is_diffview_open() then
              vim.cmd("DiffviewClose")
            else
              vim.cmd("DiffviewOpen")
            end
          end,
          desc = "Git diff toggle view",
          mode = "n",
        },
        {
          "<leader>gh",
          function()
            vim.cmd("DiffviewFileHistory %")
          end,
          desc = "Git history current file",
          mode = "n",
        },
        {
          "<leader>gH",
          function()
            vim.cmd("DiffviewFileHistory")
          end,
          desc = "Git history all files",
          mode = "n",
        },
      }
    end,
  },
}

return M
