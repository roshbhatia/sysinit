return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    lazy = false,
    config = function()
      require("neogit").setup({
        graph_style = "kitty",
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

          local handle =
            io.popen(string.format("find %s -name '.git' -maxdepth 5 -type d 2>/dev/null", vim.fn.shellescape(cwd)))
          if not handle then
            require("neogit").open()
            return
          end

          local git_dirs = {}
          for line in handle:lines() do
            -- strip trailing /.git to get the repo root
            local root = line:match("^(.+)/%.git$")
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
            local items = {}
            for _, root in ipairs(git_dirs) do
              table.insert(items, {
                text = root,
                root = root,
              })
            end

            Snacks.picker.pick({
              title = "Select Git Repo",
              items = items,
              format = "text",
              confirm = function(picker, item)
                picker:close()
                if item then
                  require("neogit").open({ cwd = item.root })
                end
              end,
            })
          end
        end,
        desc = "Toggle",
        mode = "n",
      },
    },
  },
}
