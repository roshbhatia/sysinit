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
      local layout = require("harness.diff_layout")

      -- q closes the whole review, the same as <leader>dd, so it cannot leave the
      -- other repositories' tabs open. A file-history tab is not part of a review,
      -- so it still closes on its own.
      local function close_here()
        local ok, review = pcall(require, "harness.review")
        if ok and review.here() then
          return review.close()
        end
        actions.close()
      end

      local function panel_keys(conflicts)
        local made = {
          { "n", "q", close_here, { desc = "Close the review" } },
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
          win_config = layout.file_panel,
        },
        file_history_panel = {
          win_config = layout.file_history_panel,
        },
        hooks = {
          diff_buf_read = function(bufnr)
            pcall(function()
              require("harness.notes").place(bufnr)
            end)
          end,
        },
        keymaps = {
          view = panel_keys("both"),
          file_panel = panel_keys("file"),
          file_history_panel = panel_keys("none"),
        },
      })

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
      layout.setup()
    end,
    keys = {
      {
        "<leader>dd",
        function()
          require("harness.review").toggle()
        end,
        desc = "Toggle diff",
        mode = "n",
      },
      {
        "<leader>dc",
        function()
          require("harness.changes").quickfix()
        end,
        desc = "Changed files",
        mode = "n",
      },
      {
        "<leader>dC",
        function()
          require("harness.changes").pick()
        end,
        desc = "Find changed file",
        mode = "n",
      },
      {
        "<leader>dh",
        function()
          require("harness.review").history()
        end,
        desc = "File history",
        mode = "n",
      },
      {
        "<leader>dH",
        function()
          require("harness.history").open()
        end,
        desc = "Project history",
        mode = "n",
      },
      {
        "]r",
        function()
          require("harness.review").cycle(1)
        end,
        desc = "Next repo",
        mode = "n",
      },
      {
        "[r",
        function()
          require("harness.review").cycle(-1)
        end,
        desc = "Previous repo",
        mode = "n",
      },
    },
  },
}
