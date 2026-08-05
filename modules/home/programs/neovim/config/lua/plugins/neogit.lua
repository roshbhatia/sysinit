return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "Neogit",
    config = function()
      -- Disable folds in all Neogit buffers.
      -- neogit's buffer.lua explicitly sets foldenable=true during render,
      -- so we defer with vim.schedule to run after the render completes.
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
              vim.wo[win].foldenable  = false
              vim.wo[win].foldcolumn  = "0"
              vim.wo[win].foldmethod  = "manual"
              vim.wo[win].foldexpr    = ""
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
          local cwd = vim.fn.getcwd()

          local handle = io.popen(
            string.format("fd -H -I -t d -t f --max-depth 5 '^[.]git$' %s 2>/dev/null", vim.fn.shellescape(cwd))
          )
          if not handle then
            require("neogit").open()
            return
          end

          local git_dirs = {}
          for line in handle:lines() do
            -- strip trailing /.git to get the repo root
            local root = line:match("^(.+)/%.git/?$")
            if root then
              table.insert(git_dirs, root)
            end
          end
          handle:close()

          local is_root_repo = #git_dirs == 1 and git_dirs[1] == cwd

          if is_root_repo then
            require("neogit").open()
          elseif #git_dirs == 0 then
            require("neogit").open()
          else
            vim.ui.select(git_dirs, {
              prompt = "Select Git Repo",
              format_item = function(root)
                return vim.fn.fnamemodify(root, ":~:.")
              end,
            }, function(choice)
              if choice then
                require("neogit").open({ cwd = choice })
              end
            end)
          end
        end,
        desc = "Toggle",
        mode = "n",
      },
    },
  },
}
