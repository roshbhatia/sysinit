return {
  {
    name = "harness",
    dir = vim.fn.stdpath("config") .. "/lua/harness",
    lazy = false,
    dependencies = {
      "folke/snacks.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("harness.api").setup()
    end,
    keys = {
      {
        "<leader>jj",
        function()
          require("harness.api").toggle()
        end,
        desc = "Harness: pick / toggle active agent",
      },
      {
        "<leader>ja",
        function()
          require("harness.api").ask()
        end,
        desc = "Harness: ask",
        mode = { "n", "v" },
      },
      {
        "<leader>jc",
        function()
          require("harness.api").comment()
        end,
        desc = "Harness: comment",
        mode = { "n", "v" },
      },
      {
        "<leader>jf",
        function()
          require("harness.api").fix()
        end,
        desc = "Harness: fix diagnostics",
      },
      {
        "<leader>jr",
        function()
          require("harness.api").resend()
        end,
        desc = "Harness: resend last prompt",
      },
      {
        "<leader>jx",
        function()
          require("harness.api").kill()
        end,
        desc = "Harness: kill active session",
      },
      {
        "<leader>jJ",
        function()
          require("harness.api").kill_and_pick()
        end,
        desc = "Harness: kill and re-pick",
      },
      {
        "<leader>jo",
        function()
          require("harness.api").options()
        end,
        desc = "Harness: configure options for active agent",
      },
      {
        "<leader>j?",
        function()
          require("harness.api").status()
        end,
        desc = "Harness: show active agent + options",
      },
      {
        "<leader>jb",
        function()
          require("harness.api").add_buffer()
        end,
        desc = "Harness: add current buffer",
      },
      {
        "<leader>js",
        function()
          require("harness.api").send_selection()
        end,
        desc = "Harness: send selection",
        mode = "v",
      },
      -- The glow preview moved to `<localleader>xp` in `after/ftplugin/markdown.lua`.
      -- It renders markdown, so a global key made it reachable from every filetype
      -- that it cannot render.
      --
      -- The review surface's health check has no keymap. It is a health check, so
      -- `:checkhealth harness` is where a reader already looks for it, and
      -- `harness/health.lua` registers both spellings against the same findings.
      -- The review's changed-file list needs no keymaps of its own. `after/plugin/
      -- lists.lua` already maps `]q`, `[q`, `]Q`, `[Q`, and `<leader>eq` over the
      -- quickfix list, and being generic is the point: the review is one more
      -- producer of that list, not a list of its own.
    },
  },
}
