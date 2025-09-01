local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("diffview").setup({
        diff_binaries = false,
        enhanced_diff_hl = true,
        use_icons = true,
        show_help_hints = false,
        watch_index = true,
        signs = {
          fold_closed = "▶",
          fold_open = "▼",
          done = "✓",
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info = false,
          },
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
            winbar_info = false,
          },
          file_history = {
            layout = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info = false,
          },
        },
        file_panel = {
          listing_style = "list",
          win_config = {
            position = "left",
            width = 25,
            win_opts = {
              winblend = 0,
              winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            },
          },
        },
        file_history_panel = {
          win_config = {
            position = "bottom",
            height = 10,
            win_opts = {
              winblend = 0,
              winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
            },
          },
        },
        keymaps = {
          disable_defaults = false,
          view = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          },
          file_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
            { "n", "<leader>b", false },
            { "n", "<leader>e", false },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
            { "n", "<leader>b", false },
            { "n", "<leader>e", false },
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
          desc = "Toggle diff view",
          mode = "n",
        },
        {
          "<leader>gh",
          function()
            vim.cmd("DiffviewFileHistory %")
          end,
          desc = "File history (current)",
          mode = "n",
        },
        {
          "<leader>gH",
          function()
            vim.cmd("DiffviewFileHistory")
          end,
          desc = "File history (all)",
          mode = "n",
        },
      }
    end,
  },
}

return M
