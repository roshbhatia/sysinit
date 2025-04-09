-- Coding-related plugins for code intelligence and editing

return {
  -- coq_nvim for fast, non-blocking completion
  {
    "ms-jpq/coq_nvim",
    branch = "coq",
    dependencies = {
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
      { "ms-jpq/coq.thirdparty", branch = "3p" },
    },
    event = "InsertEnter",
    config = function()
      vim.g.coq_settings = {
        auto_start = "shut-up",
        keymap = {
          recommended = true,
          jump_to_mark = "<C-Space>",
        },
        clients = {
          snippets = {
            enabled = true,
            warn = {},
          },
          tags = { enabled = true },
          lsp = { 
            enabled = true,
            always_on_complete = true,
          },
          tree_sitter = { enabled = true },
          paths = { enabled = true },
          buffers = { enabled = true },
        },
        display = {
          ghost_text = {
            enabled = true,
          },
          icons = {
            mode = "short",
          },
          pum = {
            fast_close = false,
            kind_context = { "[ ", " ]" },
          },
        },
      }
      
      -- Make sure to initialize coq after LSP setup
      local coq = require("coq")
      -- coq will be used in lsp.lua when configuring language servers
    end,
  },
  
  -- Improved snippets
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    event = "InsertEnter",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip").config.setup({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
      })
      
      -- Key mappings
      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if require("luasnip").expand_or_jumpable() then
          require("luasnip").expand_or_jump()
        end
      end, { silent = true, desc = "LuaSnip Forward" })
      
      vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if require("luasnip").jumpable(-1) then
          require("luasnip").jump(-1)
        end
      end, { silent = true, desc = "LuaSnip Backward" })
      
      vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if require("luasnip").choice_active() then
          require("luasnip").change_choice(1)
        end
      end, { silent = true, desc = "LuaSnip Next Choice" })
    end,
  },
  
  -- Faster code editing
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup({
        n_lines = 500,
        custom_textobjects = {
          o = require("mini.ai").gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
        },
      })
    end,
  },
  
  -- Easy motion for faster cursor movement
  {
    "phaazon/hop.nvim",
    event = "VeryLazy",
    config = function()
      require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
      
      -- Key mappings
      vim.keymap.set("n", "<leader>w", ":HopWord<CR>", { silent = true, desc = "Hop Word" })
      vim.keymap.set("n", "<leader>l", ":HopLine<CR>", { silent = true, desc = "Hop Line" })
      vim.keymap.set("n", "<leader>k", ":HopChar2<CR>", { silent = true, desc = "Hop 2 Chars" })
    end,
  },
  
  -- Visualize indentation
  {
    "echasnovski/mini.indentscope",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("mini.indentscope").setup({
        symbol = "│",
        options = { try_as_border = true },
        draw = {
          animation = function(_, _, hl_opts)
            return {
              delay = 0,
              steps = 1,
              on_step = function(step_idx, total_step_count, opts)
                opts.hl_group = hl_opts.hl_group
                return opts
              end,
            }
          end,
        },
      })
    end,
  },
  
  -- Structural search and replace
  {
    "cshuaimin/ssr.nvim",
    keys = {
      { "<leader>sr", function() require("ssr").open() end, desc = "Structural Replace" },
    },
  },
  
  -- Search and replace in project
  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>S", function() require("spectre").toggle() end, desc = "Toggle Spectre" },
      { "<leader>sw", function() require("spectre").open_visual({select_word=true}) end, desc = "Search Current Word" },
      { "<leader>sp", function() require("spectre").open_file_search() end, desc = "Search in Current File" },
    },
    config = function()
      require("spectre").setup({
        default = {
          find = {
            -- Default options for find
            cmd = "rg",
            options = { "ignore-case" },
          },
          replace = {
            -- Default options for replace
            cmd = "sed",
          },
        },
        mapping = {
          ["toggle_line"] = {
            map = "dd",
            cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
            desc = "toggle current item",
          },
          ["enter_file"] = {
            map = "<cr>",
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
            desc = "goto current file",
          },
          ["send_to_qf"] = {
            map = "<leader>q",
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
            desc = "send all items to quickfix",
          },
          ["replace_cmd"] = {
            map = "<leader>c",
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
            desc = "input replace command",
          },
          ["show_option_menu"] = {
            map = "<leader>o",
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = "show options",
          },
          ["run_replace"] = {
            map = "<leader>R",
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = "replace all",
          },
          ["change_view_mode"] = {
            map = "<leader>v",
            cmd = "<cmd>lua require('spectre').change_view()<CR>",
            desc = "change result view mode",
          },
        },
      })
    end,
  },
  
  -- Mini splitjoin
  {
    "echasnovski/mini.splitjoin",
    event = "VeryLazy",
    config = function()
      require("mini.splitjoin").setup()
    end,
  },
  
  -- (Twilight removed as requested)
  
  -- Better text objects
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    config = function()
      require("mini.pairs").setup()
    end,
  },
  
  -- AI code generation
  {
    "Exafunction/codeium.nvim",
    cmd = "Codeium",
    keys = {
      { "<leader>ca", ":CodeiumToggle<CR>", desc = "Toggle Codeium" },
    },
    config = function()
      require("codeium").setup({})
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
  },
}