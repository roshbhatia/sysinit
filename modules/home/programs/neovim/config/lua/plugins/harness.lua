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
      {
        "<leader>jp",
        function()
          require("harness.api").preview_spec()
        end,
        desc = "Harness: preview current file (glow)",
      },
      {
        -- Declared on this plugin rather than beside the diff keymaps because it
        -- has to answer when a diff plugin is exactly what did not load. `harness`
        -- is not lazy, so this key exists from startup.
        "<leader>d?",
        function()
          require("harness.health").show()
        end,
        desc = "Diff: health of the review surface",
      },
    },
  },
}
