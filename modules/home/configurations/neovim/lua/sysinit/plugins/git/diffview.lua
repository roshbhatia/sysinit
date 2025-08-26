local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
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
      return {
        {
          "<leader>gd",
          function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(buf) then
                local ft = vim.api.nvim_buf_get_option(buf, "filetype")
                if ft == "DiffviewFiles" then
                  found = true
                  break
                end
              end
            end
            if found then
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
          desc = "File history (current file)",
          mode = "n",
        },
        {
          "<leader>gH",
          function()
            vim.cmd("DiffviewFileHistory")
          end,
          desc = "File history (project)",
          mode = "n",
        },
        {
          "<leader>gf",
          function()
            vim.cmd("DiffviewFocusFiles")
          end,
          desc = "Focus file panel",
          mode = "n",
        },
        {
          "<leader>gt",
          function()
            vim.cmd("DiffviewToggleFiles")
          end,
          desc = "Toggle file panel",
          mode = "n",
        },
        {
          "<leader>gr",
          function()
            vim.cmd("DiffviewRefresh")
          end,
          desc = "Refresh diff view",
          mode = "n",
        },
      }
    end,
  },
}

return M
