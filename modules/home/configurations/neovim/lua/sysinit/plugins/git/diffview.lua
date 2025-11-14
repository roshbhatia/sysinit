local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
        view = {
          default = {
            winbar_info = true,
            disable_diagnostics = true,
          },
        },
        hooks = {
          diff_buf_read = function()
            vim.opt_local.signcolumn = "number"
          end,
        },
        keymaps = {
          view = {
            { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
          },
          file_panel = {
            { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
          },
          file_history_panel = {
            { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
            { "n", "<esc>", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>gdd",
        function()
          local lib = require("diffview.lib")
          local view = lib.get_current_view()
          if view then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Toggle Diffview",
      },
      {
        "<leader>gdh",
        "<cmd>DiffviewFileHistory %<CR>",
        desc = "File history (current)",
      },
      {
        "<leader>gdH",
        "<cmd>DiffviewFileHistory<CR>",
        desc = "File history (all)",
      },
    },
  },
}

return M
