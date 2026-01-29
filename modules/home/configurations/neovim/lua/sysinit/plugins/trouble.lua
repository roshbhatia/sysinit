return {
  {
    "folke/trouble.nvim",
    opts = {
      specs = {
        "folke/snacks.nvim",
        opts = function(_, opts)
          return vim.tbl_deep_extend("force", opts or {}, {
            picker = {
              actions = require("trouble.sources.snacks").actions,
              win = {
                input = {
                  keys = {
                    ["<c-t>"] = {
                      "trouble_open",
                      mode = { "n", "i" },
                    },
                  },
                },
              },
            },
          })
        end,
      },
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>cx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Project diagnostics",
      },
      {
        "<leader>cb",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer diagnostics",
      },
      {
        "<leader>cl",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Loclist diagnostics",
      },
      {
        "<leader>cq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Qflist diagnostics",
      },
    },
  },
}
