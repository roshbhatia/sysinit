return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Neogit",
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "NeogitStatus",
          "NeogitDiffView",
          "NeogitCommitView",
          "NeogitLogView",
          "NeogitRefsView",
          "NeogitReflogView",
          "NeogitStashView",
          "NeogitCommitSelectView",
          "NeogitConsole",
          "NeogitGitCommandHistory",
          "gitcommit",
          "gitrebase",
        },
        callback = function(args)
          local win = vim.api.nvim_get_current_win()
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_win_is_valid(win) then
              vim.wo[win].foldenable = false
              vim.wo[win].foldcolumn = "0"
              vim.wo[win].foldmethod = "manual"
              vim.wo[win].foldexpr = ""
            end
          end)
        end,
      })

      require("neogit").setup({
        graph_style = "kitty",
        integrations = {
          codediff = true,
          snacks = true,
        },
        diff_viewer = "codediff",
        commit_editor = {
          staged_diff_split_kind = "auto",
        },
        mappings = {
          commit_editor = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
            ["<localleader>mp"] = "PrevMessage",
            ["<localleader>mn"] = "NextMessage",
            ["<localleader>mr"] = "ResetMessage",
          },
          commit_editor_I = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
          },
          rebase_editor = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
            ["[uu"] = "OpenOrScrollUp",
            ["]ud"] = "OpenOrScrollDown",
          },
          rebase_editor_I = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
          },
          finder = {
            ["<localleader>q"] = "Close",
            ["<localleader>n"] = "Next",
            ["<localleader>p"] = "Previous",
            ["<down>"] = "Next",
            ["<up>"] = "Previous",
            ["<localleader>y"] = "CopySelection",
          },
          status = {
            ["<localleader>S"] = "StageAll",
            ["<localleader>r"] = "RefreshBuffer",
            ["<localleader>v"] = "VSplitOpen",
            ["<localleader>s"] = "SplitOpen",
            ["<localleader>t"] = "TabOpen",
            ["[uu"] = "OpenOrScrollUp",
            ["]ud"] = "OpenOrScrollDown",
            ["<localleader>k"] = "PeekUp",
            ["<localleader>j"] = "PeekDown",
            ["<localleader>n"] = "NextSection",
            ["<localleader>p"] = "PreviousSection",
          },
        },
      })
    end,
    keys = {
      {
        "<leader>gg",
        function()
          -- Neogit resolves its root from nvim's cwd, not from the buffer, so a
          -- workspace holding several repos needs the root passed in.
          --
          -- Still one repository, deliberately: a status buffer spanning several
          -- would be a fiction. What changed is that `resolve` now sees a repository
          -- nested inside the workspace, so the buffer's own checkout can win over
          -- the outer one instead of being invisible.
          require("utils.gitrepo").resolve(function(root)
            require("neogit").open({ cwd = root })
          end)
        end,
        desc = "Toggle",
        mode = "n",
      },
    },
  },
}
