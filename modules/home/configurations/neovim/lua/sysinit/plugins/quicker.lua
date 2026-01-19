return {
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    keys = {
      {
        "<leader>q",
        function()
          require("quicker").toggle()
        end,
        desc = "Toggle quickfix",
      },
      {
        "<leader>Q",
        function()
          require("quicker").toggle({ loclist = true })
        end,
        desc = "Toggle loclist",
      },
    },
    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
      highlight = {
        treesitter = true,
        lsp = true,
        load_buffers = false,
      },
      edit = {
        enabled = true,
        autosave = "unmodified",
      },
      type_icons = {
        E = " ",
        W = " ",
        I = " ",
        N = " ",
        H = " ",
      },
    },
  },
}
