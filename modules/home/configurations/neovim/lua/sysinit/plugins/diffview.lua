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
            c.width = math.floor(editor_width * 0.9)
            c.height = math.min(16, math.floor(editor_height * 0.3))
            c.col = math.floor((editor_width - c.width) * 0.5)
            c.row = editor_height - c.height - 2
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
        function()
          if vim.g.diffview_is_open then
            vim.cmd("DiffviewClose")
            vim.g.diffview_is_open = false
          else
            vim.cmd("DiffviewOpen")
            vim.g.diffview_is_open = true
          end
        end,
        desc = "Toggle diffview",
      },
      {
        "<leader>df",
        function()
          vim.cmd("DiffviewOpen --selected-file")
          vim.cmd("DiffviewToggleFiles")
          vim.g.diffview_is_open = true
        end,
        desc = "File diff",
      },
      {
        "<leader>de",
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
        function()
          vim.cmd("DiffviewClose")
          vim.g.diffview_is_open = false
        end,
        desc = "Close diffview",
      },
    },
  },
}
