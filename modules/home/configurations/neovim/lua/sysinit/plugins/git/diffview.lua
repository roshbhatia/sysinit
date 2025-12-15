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
          view_enter = function()
            vim.cmd("silent! DisableHLChunk")
          end,
          diff_buf_read = function()
            vim.opt_local.signcolumn = "no"

            vim.opt_local.number = true
            vim.opt_local.relativenumber = false

            local ok, foldsign = pcall(require, "nvim-foldsign")
            if ok then
              vim.api.nvim_buf_clear_namespace(0, foldsign.ns, 0, -1)
            end
          end,

          view_closed = function()
            vim.cmd("silent! EnableHLChunk")
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
        "<leader>dd",
        function()
          local lib = require("diffview.lib")
          local view = lib.get_current_view()
          if view then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Diff: Toggle (HEAD)",
      },
      {
        "<leader>dm",
        function()
          vim.cmd("DiffviewOpen main")
        end,
        desc = "Diff: Main",
      },
      {
        "<leader>dD",
        "<cmd>DiffviewFileHistory<CR>",
        desc = "Diff: History (File)",
      },
    },
  },
}

return M
