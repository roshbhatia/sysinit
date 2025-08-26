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
             -- Toggle Diffview: if open, close; if closed, open
             local tabpages = vim.api.nvim_list_tabpages()
             local found = false
             for _, tab in ipairs(tabpages) do
               local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, 'diffview_view')
               if ok and name then
                 found = true
                 break
               end
             end
             if found then
               vim.cmd("DiffviewClose")
             else
               vim.cmd("DiffviewOpen")
             end
           end,
           desc = "Git: Toggle diff view",
           mode = "n",
        },

        {
          "<leader>gh",
          function()
            vim.cmd("DiffviewFileHistory %")
          end,
          desc = "Git: File history (current file)",
          mode = "n",
        },
        {
          "<leader>gH",
          function()
            vim.cmd("DiffviewFileHistory")
          end,
          desc = "Git: File history (project)",
          mode = "n",
        },
        {
          "<leader>gf",
          function()
            vim.cmd("DiffviewFocusFiles")
          end,
          desc = "Git: Focus file panel",
          mode = "n",
        },
        {
          "<leader>gt",
          function()
            vim.cmd("DiffviewToggleFiles")
          end,
          desc = "Git: Toggle file panel",
          mode = "n",
        },
        {
          "<leader>gr",
          function()
            vim.cmd("DiffviewRefresh")
          end,
          desc = "Git: Refresh diff view",
          mode = "n",
        },
      }
    end,
  },
}

return M
