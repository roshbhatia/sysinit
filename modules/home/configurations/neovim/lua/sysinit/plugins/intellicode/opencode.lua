local agents_config = require("sysinit.config.agents_config").load_config()
local M = {}

M.plugins = {
  {
    enabled = agents_config.agents.enabled and agents_config.agents.opencode.enabled,
    "NickvanDyke/opencode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("opencode").setup({
        auto_reload = false,
      })

      local tmp_dir = "/tmp"
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("OpencodeAutoDiff", { clear = true }),
        pattern = "OpencodeEvent",
        callback = function(args)
          if args.data and args.data.type == "file.edited" then
            local bufnr = vim.api.nvim_get_current_buf()
            local filename = vim.api.nvim_buf_get_name(bufnr)
            local tmpfile = tmp_dir .. "/opencode_before_" .. bufnr .. ".tmp"
            vim.fn.system({ "rsync", "-a", filename, tmpfile })
            vim.cmd("checktime")
            vim.cmd("vert diffsplit " .. tmpfile)
          end
        end,
        desc = "Show vimdiff of opencode edits",
      })
    end,
    keys = {
      {
        "<leader>jj",
        function()
          require("snacks.terminal").toggle("opencode", {
            win = {
              position = "right",
              title = false,
            },
          })
        end,
        desc = "Toggle opencode",
      },
      {
        "<leader>ja",
        function()
          require("opencode").ask()
        end,
        desc = "Ask opencode",
        mode = { "n", "v" },
      },
      {
        "<leader>jA",
        function()
          require("opencode").ask("@file ")
        end,
        desc = "Ask opencode about current file",
        mode = { "n", "v" },
      },
      {
        "<leader>jJ",
        function()
          require("opencode").command("/new")
        end,
        desc = "New session",
      },
      {
        "<leader>je",
        function()
          require("opencode").prompt("Explain @cursor and its context")
        end,
        desc = "Explain code near cursor",
      },
      {
        "<leader>jr",
        function()
          require("opencode").prompt("Review @file for correctness and readability")
        end,
        desc = "Review file",
      },
      {
        "<leader>jf",
        function()
          require("opencode").prompt("Fix these @diagnostics")
        end,
        desc = "Fix errors",
      },
      {
        "<leader>jo",
        function()
          require("opencode").prompt("Optimize @selection for performance and readability")
        end,
        desc = "Optimize selection",
        mode = "v",
      },
      {
        "<leader>jd",
        function()
          require("opencode").prompt("Add documentation comments for @selection")
        end,
        desc = "Document selection",
        mode = "v",
      },
      {
        "<leader>jt",
        function()
          require("opencode").prompt("Add tests for @selection")
        end,
        desc = "Test selection",
        mode = "v",
      },
    },
  },
}

return M

