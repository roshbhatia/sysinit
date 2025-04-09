-- Enhanced editor experience (like VSCode)
return {
  -- Better autopairs with treesitter integration
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup({
        check_ts = true, -- Use treesitter to check for pairs
        ts_config = {
          lua = {"string", "source"},
          javascript = {"string", "template_string"},
        },
        disable_filetype = {"TelescopePrompt", "spectre_panel"},
        fast_wrap = {
          map = "<M-e>",  -- Alt+e to wrap with pairs
          chars = {"{", "[", "(", '"', "'"},
          pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
          offset = 0,
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "PmenuSel",
          highlight_grey = "LineNr",
        },
      })

      -- Make it work with cmp
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp_ok, cmp = pcall(require, "cmp")
      if cmp_ok then
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
      
      -- Add spaces between parentheses
      local Rule = require("nvim-autopairs.rule")
      local brackets = {{"(", ")"}, {"[", "]"}, {"{", "}"}}
      npairs.add_rules {
        -- Add space between brackets
        Rule(" ", " ")
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1] .. brackets[1][2],
              brackets[2][1] .. brackets[2][2],
              brackets[3][1] .. brackets[3][2],
            }, pair)
          end),
        -- Auto add space on =
        Rule("=", "")
          :with_pair(function() return false end)
          :with_move(function(opts) return opts.prev_char:match(".%=$") ~= nil end)
          :use_key("="),
      }
    end,
  },
  
  -- Trim whitespace and ensure newlines at EOF
  {
    "McAuleyPenney/tidy.nvim",
    event = "BufWritePre",
    opts = {
      enabled_on_save = true,
      timeout = 500,
    },
  },
  
  -- Align text
  {
    "junegunn/vim-easy-align", 
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = {"n", "x"}, desc = "Easy Align" },
    },
    config = function()
      -- Create some helpful commands
      vim.api.nvim_create_user_command("AlignEquals", "EasyAlign =", { range = true })
      vim.api.nvim_create_user_command("AlignComma", "EasyAlign ,", { range = true })
      vim.api.nvim_create_user_command("AlignPipe", "EasyAlign |", { range = true })
      
      -- Add key mappings with which-key
      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.register({
          ["<leader>a="] = { ":AlignEquals<CR>", "Align at equals" },
          ["<leader>a,"] = { ":AlignComma<CR>", "Align at commas" },
          ["<leader>a|"] = { ":AlignPipe<CR>", "Align at pipes" },
        }, { mode = "v" })
      end
    end,
  },
  
  -- Rainbow brackets and enhanced highlighting
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local rainbow_delimiters = require('rainbow-delimiters')
      require('rainbow-delimiters.setup').setup {
        strategy = {
          [''] = rainbow_delimiters.strategy['global'],
          vim = rainbow_delimiters.strategy['local'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
        highlight = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        },
      }
    end,
  },
  
  -- Match and highlight brackets
  {
    "andymass/vim-matchup",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
      vim.g.matchup_surround_enabled = 1
      vim.g.matchup_motion_enabled = 1
      vim.g.matchup_text_obj_enabled = 1
    end,
  },
  
  -- Enhanced multi-cursor support
  {
    "mg979/vim-visual-multi",
    event = "BufReadPost",
    init = function()
      vim.g.VM_leader = '\\'
      vim.g.VM_maps = {
        ["Find Under"] = '<C-d>',
        ["Find Subword Under"] = '<C-d>',
      }
    end,
  },
  
  -- Highlight active indentation
  {
    "echasnovski/mini.indentscope",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      symbol = "│",
      options = { try_as_border = true },
      draw = {
        animation = function(s, n) return 5 end -- Smooth animation
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy",
          "mason", "notify", "toggleterm", "lazyterm",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
  
  -- Automatic bracket and tag completion
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },
  
  -- Smart commenting with treesitter support
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        mappings = {
          basic = true,
          extra = true,
        },
      })
    end,
  },
  
  -- Additional text objects
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter-textobjects" },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }, {}),
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)
      
      -- Register with which-key if available
      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        local i = {
          ["]f"] = { "Next function" },
          ["]c"] = { "Next class" },
          ["]a"] = { "Next argument" },
          ["]o"] = { "Next block" },
          ["[f"] = { "Previous function" },
          ["[c"] = { "Previous class" },
          ["[a"] = { "Previous argument" },
          ["[o"] = { "Previous block" },
        }
        wk.register(i)
      end
    end,
  },
  
  -- Multiple cursors support
  {
    "terryma/vim-multiple-cursors",
    event = "VeryLazy",
  },
  
  -- VSCode-like inline hint decorations
  {
    "lvimuser/lsp-inlayhints.nvim",
    event = "LspAttach",
    opts = {
      inlay_hints = {
        type_hints = {
          prefix = "=> ",
          highlight = "LspInlayHint",
        },
        parameter_hints = {
          prefix = "<- ",
          highlight = "LspInlayHint",
        },
      },
    },
  },
}
