local M = {}

M.plugins = {
  {
    "esmuellert/vscode-diff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = "make",
    cmd = "CodeDiff",
    config = function()
      require("vscode-diff").setup({})
    end,

    keys = {
      {
        "<leader>gdd",
        function()
          local current_tab = vim.api.nvim_get_current_tabpage()
          local tabs = vim.api.nvim_list_tabpages()
          local found_diff_tab = false

          for _, tab in ipairs(tabs) do
            local win = vim.api.nvim_tabpage_get_win(tab)
            local buf = vim.api.nvim_win_get_buf(win)
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname:match("CodeDiff") then
              found_diff_tab = true
              if tab == current_tab then
                vim.cmd("tabclose")
              else
                vim.api.nvim_set_current_tabpage(tab)
              end
              break
            end
          end

          if not found_diff_tab then
            vim.cmd("CodeDiff")
          end
        end,
        desc = "Toggle CodeDiff",
      },
      {
        "<leader>gdh",
        function()
          vim.cmd("CodeDiff file HEAD")
        end,
        desc = "Diff current file (HEAD)",
      },
      {
        "<leader>gdH",
        function()
          vim.cmd("CodeDiff HEAD")
        end,
        desc = "Diff explorer (HEAD)",
      },
    },
  },
}

return M
