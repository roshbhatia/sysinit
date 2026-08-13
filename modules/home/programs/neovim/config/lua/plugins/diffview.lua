return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = {
      "Review",
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
          -- `q` closes the review from anywhere inside it, the way every other panel in
          -- this config closes.
          view = {
            { "n", "q", actions.close, { desc = "Close the review" } },
          },
          file_panel = {
            { "n", "q", actions.close, { desc = "Close the review" } },
          },
          file_history_panel = {
            { "n", "q", actions.close, { desc = "Close the review" } },
          },
        },
      })

      -- The rest of the review under one command rather than one key each: these are asked
      -- for a few times a week, and `<leader>d` had grown a key for every one of them.
      local jobs = {
        pick = function()
          require("harness.review").pick()
        end,
        all = function()
          require("harness.review").all()
        end,
        scope = function()
          require("harness.scopes").open()
        end,
        base = function()
          require("harness.review").set_base()
        end,
        refresh = function()
          require("harness.review").refresh()
        end,
      }
      vim.api.nvim_create_user_command("Review", function(cmd)
        local job = jobs[cmd.args ~= "" and cmd.args or "pick"]
        if job == nil then
          vim.notify("Review: no such subcommand " .. cmd.args, vim.log.levels.WARN)
          return
        end
        job()
      end, {
        nargs = "?",
        complete = function()
          return vim.tbl_keys(jobs)
        end,
        desc = "Review: pick, all, scope, base, refresh",
      })

      require("harness.notes_list").setup()
    end,
    keys = {
      {
        "<leader>dd",
        function()
          require("harness.review").toggle()
        end,
        desc = "Review: the repo you are in, or a pick",
        mode = "n",
      },
      {
        "<leader>dh",
        function()
          require("harness.review").history()
        end,
        desc = "History of this file",
        mode = "n",
      },
      {
        "<leader>dH",
        function()
          require("harness.history").open()
        end,
        desc = "History of this repo, or of every repo by time",
        mode = "n",
      },
      {
        "<leader>dnq",
        function()
          require("harness.notes_list").quickfix()
        end,
        desc = "Notes in the quickfix, kept current",
        mode = "n",
      },
      {
        "<leader>dnf",
        function()
          require("harness.notes_list").pick()
        end,
        desc = "Find a note",
        mode = "n",
      },
      -- `]r`, not `]d`: the LSP attaches `]d` per buffer for diagnostics, and a global
      -- mapping under it would answer only in the buffers the LSP never reached.
      {
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
