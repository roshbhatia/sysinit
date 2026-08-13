return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },
    config = function()
      local actions = require("diffview.actions")

      require("diffview").setup({
        enhanced_diff_hl = true,
        show_help_hints = false,
        view = {
          merge_tool = { layout = "diff3_mixed" },
        },
        file_panel = {
          listing_style = "tree",
          win_config = { position = "left", width = 32 },
        },
        file_history_panel = {
          win_config = { position = "bottom", height = 14 },
        },
        hooks = {
          -- The notes are drawn per buffer as it is shown, and diffview loads its buffers
          -- after the view opens, so they are placed here rather than at open time.
          diff_buf_read = function(bufnr)
            pcall(function()
              require("harness.notes").place(bufnr)
            end)
          end,
          -- A view closed by `q` or `:DiffviewClose` never went through the driver, so the
          -- notes would stay attached to a review that is no longer on screen.
          view_closed = function()
            vim.schedule(function()
              local ok, review = pcall(require, "harness.review")
              if ok and not review.is_open() then
                pcall(function()
                  require("harness.notes").detach()
                end)
              end
            end)
          end,
        },
        keymaps = {
          view = {
            { "n", "<leader>dq", actions.close, { desc = "Close the review" } },
          },
          file_panel = {
            { "n", "<leader>dq", actions.close, { desc = "Close the review" } },
          },
          file_history_panel = {
            { "n", "<leader>dq", actions.close, { desc = "Close the review" } },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>dr",
        function()
          require("harness.review").toggle()
        end,
        desc = "Toggle the review",
        mode = "n",
      },
      {
        "<leader>dd",
        function()
          require("harness.review").pick()
        end,
        desc = "Review a repo, picked from those with changes",
        mode = "n",
      },
      {
        "<leader>da",
        function()
          require("harness.review").all()
        end,
        desc = "Review every changed repo at once",
        mode = "n",
      },
      {
        "<leader>ds",
        function()
          require("harness.scopes").open()
        end,
        desc = "Pick the review scope",
        mode = "n",
      },
      {
        "<leader>dq",
        function()
          require("harness.review").close()
        end,
        desc = "Close the review",
        mode = "n",
      },
      {
        "<leader>db",
        function()
          require("harness.review").set_base()
        end,
        desc = "Compare the working tree back to a commit",
        mode = "n",
      },
      {
        "<leader>dH",
        function()
          require("harness.review").repo_history()
        end,
        desc = "Repo history, as a list of commits",
        mode = "n",
      },
      {
        "<leader>dh",
        function()
          require("harness.review").file_history()
        end,
        desc = "Current file history",
        mode = "n",
      },
      {
        "<leader>dR",
        function()
          require("harness.review").refresh()
        end,
        desc = "Reload the review and its notes",
        mode = "n",
      },
      {
        -- `]r`, not `]d`: the LSP attaches `]d` per buffer for diagnostics, and a global
        -- mapping under it would answer only in the buffers the LSP never reached.
        "]r",
        function()
          require("harness.review").cycle(1)
        end,
        desc = "Next repo under review",
        mode = "n",
      },
      {
        "[r",
        function()
          require("harness.review").cycle(-1)
        end,
        desc = "Prev repo under review",
        mode = "n",
      },
    },
  },
}
