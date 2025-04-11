local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    priority = 900,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "mrjones2014/legendary.nvim"
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
  local legendary = require("legendary")

  -- Command Palette Commands
  local command_palette_commands = {
    {
      description = "Treesitter: Install Language",
      command = "<cmd>TSInstall<CR>",
      category = "Treesitter"
    },
    {
      description = "Treesitter: Update Parsers",
      command = "<cmd>TSUpdate<CR>",
      category = "Treesitter"
    },
    {
      description = "Treesitter: Show Language Info",
      command = "<cmd>TSModuleInfo<CR>",
      category = "Treesitter"
    }
  }

  -- Register with Legendary
  legendary.commands(command_palette_commands)

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
      desc = "Command Palette Commands",
      command = ":Legendary commands",
      expected = "Should show Treesitter commands in Command Palette"
    }
  })
end

return M