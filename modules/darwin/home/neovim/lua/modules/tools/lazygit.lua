-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/kdheepak/lazygit.nvim/refs/heads/main/README.md"
local M = {}

M.plugins = {
  {
    "kdheepak/lazygit.nvim",
    lazy = false,
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Floating window settings
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_floating_window_scaling_factor = 0.9
      vim.g.lazygit_floating_window_border_chars = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }
      vim.g.lazygit_floating_window_use_plenary = 0
      -- Use neovim-remote for commit messages if available
      vim.g.lazygit_use_neovim_remote = 1

      -- Which-key mappings for LazyGit
      local wk = require("which-key")
      wk.add({
        { "<leader>g", group = "Git", icon = { icon = "", hl = "WhichKeyIconRed" } }, -- vscode actions: git.stage, git.stageAll, git.unstage, git.unstageAll, git.commit, git.commitAll, git.push, git.pull, git.openChange, git.openAllChanges, git.checkout, git.fetch, git.revertChange, workbench.view.scm, workbench.action.chat.open
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "Open LazyGit", mode = "n" },
        { "<leader>gc", "<cmd>LazyGitCurrentFile<CR>", desc = "LazyGit (Current File)", mode = "n" },
        { "<leader>gf", "<cmd>LazyGitFilter<CR>", desc = "LazyGit (Filter)", mode = "n" },
        { "<leader>gF", "<cmd>LazyGitFilterCurrentFile<CR>", desc = "LazyGit (Filter Current File)", mode = "n" },
        { "<leader>gC", "<cmd>LazyGitConfig<CR>", desc = "Edit LazyGit Config", mode = "n" },
      })

      -- Load Telescope extension if present
      pcall(function()
        require("telescope").load_extension("lazygit")
      end)
    end,
  },
}

return M
