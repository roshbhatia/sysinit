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
        process_spinner = true,
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
          require("neogit").open()
        end,
        desc = "Toggle",
        mode = "n",
      },
      {
        "<leader>gc",
        function()
          require("neogit").open({ "commit" })
        end,
        desc = "Commit",
        mode = "n",
      },
      {
        "<leader>gp",
        function()
          require("neogit").open({ "push" })
        end,
        desc = "Push",
        mode = "n",
      },
      {
        "<leader>gP",
        function()
          require("neogit").open({ "pull" })
        end,
        desc = "Pull",
        mode = "n",
      },
      {
        "<leader>ge",
        function()
          require("neogit").open({ "branch" })
        end,
        desc = "Branch",
        mode = "n",
      },
      {
        "<leader>gl",
        function()
          require("neogit").open({ "log" })
        end,
        desc = "Log",
        mode = "n",
      },
    },
  },
}
