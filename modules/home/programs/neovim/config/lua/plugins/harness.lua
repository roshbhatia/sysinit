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
        desc = "Pick or toggle agent",
      },
      {
        "<leader>ja",
        function()
          require("harness.api").ask()
        end,
        desc = "Ask",
        mode = { "n", "v" },
      },
      {
        "<leader>jc",
        function()
          require("harness.api").comment()
        end,
        desc = "Comment",
        mode = { "n", "v" },
      },
      {
        "<leader>jf",
        function()
          require("harness.api").fix()
        end,
        desc = "Fix diagnostics",
      },
      {
        "<leader>jr",
        function()
          require("harness.api").resend()
        end,
        desc = "Resend last prompt",
      },
      {
        "<leader>jx",
        function()
          require("harness.api").kill()
        end,
        desc = "Kill agent",
      },
      {
        "<leader>jJ",
        function()
          require("harness.api").kill_and_pick()
        end,
        desc = "Kill agent and pick again",
      },
      {
        "<leader>jo",
        function()
          require("harness.api").options()
        end,
        desc = "Agent options",
      },
      {
        "<leader>j?",
        function()
          require("harness.api").status()
        end,
        desc = "Agent status",
      },
      {
        "<leader>jb",
        function()
          require("harness.api").add_buffer()
        end,
        desc = "Add buffer",
      },
      {
        "<leader>js",
        function()
          require("harness.api").send_selection()
        end,
        desc = "Send selection",
        mode = "v",
      },
      {
        "<leader>dna",
        function()
          require("harness.notes").add()
        end,
        desc = "Add note on this line",
      },
      {
        "<leader>dnt",
        function()
          require("harness.notes").toggle()
        end,
        desc = "Toggle notes",
      },
      {
        "<leader>dnd",
        function()
          require("harness.notes").remove_line()
        end,
        desc = "Delete notes on this line",
      },
      {
        "<leader>dnD",
        function()
          require("harness.notes").remove_file()
        end,
        desc = "Delete notes in this file",
      },
      {
        "<leader>dnX",
        function()
          require("harness.notes").remove_all()
        end,
        desc = "Delete every note",
      },
      {
        "<leader>dnq",
        function()
          require("harness.notes_list").quickfix()
        end,
        desc = "Quickfix notes",
      },
      {
        "<leader>dnf",
        function()
          require("harness.notes_list").pick()
        end,
        desc = "Find note",
      },
    },
  },
}
