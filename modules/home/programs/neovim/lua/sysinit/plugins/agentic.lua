return {
  {
    "carlos-algms/agentic.nvim",
    opts = {},
    keys = {
      {
        "<leader>oo",
        function()
          require("agentic").toggle()
        end,
        mode = { "n" },
        desc = "Toggle Agentic Chat",
      },
      {
        "<localleader>oa",
        function()
          require("agentic").add_selection_or_file_to_context()
        end,
        mode = { "n", "v" },
        desc = "Add file or selection to Agentic to Context",
      },
      {
        "<leader>oO",
        function()
          require("agentic").new_session()
        end,
        mode = { "n" },
        desc = "New Agentic Session",
      },
      {
        "<leader>of",
        function()
          require("agentic").restore_session()
        end,
        desc = "Agentic Restore session",
        silent = true,
        mode = { "n" },
      },
    },
  },
}
