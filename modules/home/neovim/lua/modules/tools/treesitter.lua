local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    priority = 900,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects"
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "css", "go", "html", "javascript",
          "json", "lua", "markdown", "markdown_inline", "python",
          "regex", "rust", "toml", "tsx", "typescript", "vim",
          "yaml", "nix", "comment"
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        autopairs = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
        },
      })
    end
  }
}

function M.setup()
  local commander = require("commander")

  -- Register treesitter text object descriptions
  -- (These are already mapped by treesitter config, but we add them to Commander for documentation)
  commander.add({
    {
      desc = "Around Function",
      cmd = "af",
      keys = { {"o", "x"}, "af" },
      cat = "Treesitter Textobject"
    },
    {
      desc = "Inside Function",
      cmd = "if",
      keys = { {"o", "x"}, "if" },
      cat = "Treesitter Textobject"
    },
    {
      desc = "Around Class",
      cmd = "ac",
      keys = { {"o", "x"}, "ac" },
      cat = "Treesitter Textobject"
    },
    {
      desc = "Inside Class",
      cmd = "ic",
      keys = { {"o", "x"}, "ic" },
      cat = "Treesitter Textobject"
    },
    {
      desc = "Around Block",
      cmd = "ab",
      keys = { {"o", "x"}, "ab" },
      cat = "Treesitter Textobject"
    },
    {
      desc = "Inside Block",
      cmd = "ib",
      keys = { {"o", "x"}, "ib" },
      cat = "Treesitter Textobject"
    },
    -- Navigation commands
    {
      desc = "Next Function Start",
      cmd = "]f",
      keys = { "n", "]f" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Next Class Start",
      cmd = "]c",
      keys = { "n", "]c" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Next Function End",
      cmd = "]F",
      keys = { "n", "]F" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Next Class End",
      cmd = "]C",
      keys = { "n", "]C" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Previous Function Start",
      cmd = "[f",
      keys = { "n", "[f" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Previous Class Start",
      cmd = "[c",
      keys = { "n", "[c" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Previous Function End",
      cmd = "[F",
      keys = { "n", "[F" },
      cat = "Treesitter Navigation"
    },
    {
      desc = "Previous Class End",
      cmd = "[C",
      keys = { "n", "[C" },
      cat = "Treesitter Navigation"
    },
    -- Treesitter commands
    {
      desc = "Install Treesitter Language",
      cmd = "<cmd>TSInstall ",
      cat = "Treesitter"
    },
    {
      desc = "Update Treesitter Parsers",
      cmd = "<cmd>TSUpdate<CR>",
      keys = { "n", "<leader>tu" },
      cat = "Treesitter"
    },
    {
      desc = "Show Treesitter Module Info",
      cmd = "<cmd>TSModuleInfo<CR>",
      keys = { "n", "<leader>ti" },
      cat = "Treesitter"
    }
  })

  -- Register verification steps
  verify.register_verification("treesitter", {
    {
      desc = "Treesitter Module Info",
      command = ":TSModuleInfo",
      expected = "Should show installed Treesitter modules"
    },
    {
      desc = "Syntax Highlighting",
      command = "Open a code file",
      expected = "Should show syntax highlighting"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=Treesitter",
      expected = "Should show Treesitter commands in Commander palette"
    },
    {
      desc = "Text Objects",
      command = "vaf in a function",
      expected = "Should select the entire function"
    }
  })
end

return M