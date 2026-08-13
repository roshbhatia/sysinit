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

      -- Everything diffview binds inside a review lives under `<localleader>d`: `d` for
      -- the diff, and a local leader because `<leader>e`, `<leader>b`, and `<leader>c*`
      -- are the explorer and the code group everywhere else in this config.
      local function panel_keys(conflicts)
        local made = {
          { "n", "q", actions.close, { desc = "Close the review" } },
          { "n", "<leader>e", false },
          { "n", "<leader>b", false },
          { "n", "<localleader>de", actions.focus_files, { desc = "Focus the file panel" } },
          { "n", "<localleader>db", actions.toggle_files, { desc = "Toggle the file panel" } },
        }
        for _, key in ipairs({ "o", "t", "b", "a" }) do
          local which = ({ o = "ours", t = "theirs", b = "base", a = "all" })[key]
          if conflicts == "hunk" or conflicts == "both" then
            made[#made + 1] = { "n", "<leader>c" .. key, false }
            made[#made + 1] = {
              "n",
              "<localleader>dc" .. key,
              actions.conflict_choose(which),
              { desc = "Take " .. which },
            }
          end
          if conflicts == "file" or conflicts == "both" then
            made[#made + 1] = { "n", "<leader>c" .. key:upper(), false }
            made[#made + 1] = {
              "n",
              "<localleader>dc" .. key:upper(),
              actions.conflict_choose_all(which),
              { desc = "Take " .. which .. " for the whole file" },
            }
          end
        end
        return made
      end

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
          view = panel_keys("both"),
          file_panel = panel_keys("file"),
          file_history_panel = panel_keys("none"),
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
        desc = "Diff: toggle",
        mode = "n",
      },
      {
        "<leader>dh",
        function()
          require("harness.review").history()
        end,
        desc = "Diff: file history",
        mode = "n",
      },
      {
        "<leader>dH",
        function()
          require("harness.history").open()
        end,
        desc = "Diff: project history",
        mode = "n",
      },
      {
        "<leader>dnq",
        function()
          require("harness.notes_list").quickfix()
        end,
        desc = "Diff: quickfix notes",
        mode = "n",
      },
      {
        "<leader>dnf",
        function()
          require("harness.notes_list").pick()
        end,
        desc = "Diff: find notes",
        mode = "n",
      },
      -- `]r`, not `]d`: the LSP attaches `]d` per buffer for diagnostics, and a global
      -- mapping under it would answer only in the buffers the LSP never reached.
      {
        "]r",
        function()
          require("harness.review").cycle(1)
        end,
        desc = "Diff: next repo",
        mode = "n",
      },
      {
        "[r",
        function()
          require("harness.review").cycle(-1)
        end,
        desc = "Diff: previous repo",
        mode = "n",
      },
    },
  },
}
