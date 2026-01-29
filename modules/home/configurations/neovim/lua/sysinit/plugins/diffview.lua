return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = {
      "DiffviewOpen",
    },
    config = function()
      require("diffview").setup({
        default_args = {
          DiffviewOpen = { "--imply-local" },
        },
        file_panel = {
          win_config = function()
            local c = { type = "float" }
            local editor_width = vim.o.columns
            local editor_height = vim.o.lines
            c.width = math.min(100, editor_width)
            c.height = math.min(24, editor_height)
            c.col = math.floor(editor_width * 0.5 - c.width * 0.5)
            c.row = math.floor(editor_height * 0.5 - c.height * 0.5)
            return c
          end,
        },
        hooks = {
          diff_buf_read = function(bufnr)
            vim.diagnostic.disable(bufnr)
            vim.opt_local.list = false
            vim.opt_local.wrap = false
          end,
        },
        view = {
          merge_tool = {
            layout = "diff3_mixed",
          },
        },
      })
    end,
    keys = {
      {
        "<leader>dd",
        "<Cmd>DiffviewOpen<CR>",
        desc = "Diff against index",
      },
      {
        "<leader>df",
        "<Cmd>DiffviewToggleFiles<CR>",
        desc = "Toggle file panel",
      },
      {
        "<leader>dm",
        function()
          vim.fn.system("git rev-parse --verify main 2>/dev/null")
          if vim.v.shell_error == 0 then
            vim.cmd("DiffviewOpen main")
          else
            vim.cmd("DiffviewOpen master")
          end
        end,
        desc = "Diff against default branch",
      },
      {
        "<leader>dh",
        "<Cmd>DiffviewFileHistory %<CR>",
        desc = "File history",
      },
      {
        "<leader>dH",
        "<Cmd>DiffviewFileHistory<CR>",
        desc = "Branch history",
      },
      {
        "<leader>dc",
        "<Cmd>DiffviewClose<CR>",
        desc = "Close diffview",
      },
    },
  },
}
