-- Enhanced integration between WezTerm and Neovim
return {
  -- ToggleTerm is a key component for WezTerm integration
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        -- Terminal window size and position
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
        winbar = {
          enabled = true,
          name_formatter = function(term)
            return term.name
          end,
        },
      })

      -- Define multiple terminals for different contexts
      local Terminal = require("toggleterm.terminal").Terminal

      -- Lazygit terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float",
        float_opts = {
          border = "double",
        },
      })

      -- Top terminal
      local top = Terminal:new({
        cmd = "top",
        hidden = true,
        direction = "float",
      })

      -- Python REPL
      local python = Terminal:new({
        cmd = "python",
        hidden = true,
        direction = "horizontal",
      })

      -- Register keymap for each terminal
      vim.keymap.set("n", "<leader>tg", function()
        lazygit:toggle()
      end, { desc = "Toggle Lazygit" })

      vim.keymap.set("n", "<leader>tt", function()
        top:toggle()
      end, { desc = "Toggle Top" })

      vim.keymap.set("n", "<leader>tp", function()
        python:toggle()
      end, { desc = "Toggle Python REPL" })

      -- Quick terminal float
      vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { desc = "Toggle floating terminal" })
      
      -- Quick terminal horizontal
      vim.keymap.set("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", { desc = "Toggle horizontal terminal" })
      
      -- Quick terminal vertical
      vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", { desc = "Toggle vertical terminal" })
      
      -- Terminal navigation
      function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        -- Exit terminal mode with Escape
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        -- Navigate between windows in terminal mode
        vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
        -- Navigate between terminals
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
      end
      
      vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
    end,
  },
  
  -- Fix for ZSH/WezTerm highlighting issues
  {
    "folke/tokyonight.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      -- Set up autocommands to fix terminal highlighting
      vim.api.nvim_create_autocmd({"TermEnter", "TermOpen", "BufEnter"}, {
        pattern = {"term://*"},
        callback = function()
          -- Fix bright red blocks issue in ZSH
          vim.opt_local.cursorline = false
          vim.opt_local.cursorcolumn = false
          
          -- Disable search highlighting in terminal
          vim.opt_local.hlsearch = false
          
          -- Fix terminal coloring
          vim.api.nvim_set_hl(0, "Terminal", { fg = "#c0caf5", bg = "#1a1b26" })
          
          -- Fix selection highlighting in terminal
          vim.api.nvim_set_hl(0, "TermCursor", { bg = "#c0caf5" })
          vim.api.nvim_set_hl(0, "TermCursorNC", { bg = "#6b7089" })
          
          -- Fix ZSH syntax highlighting
          vim.api.nvim_set_hl(0, "zshPrecommand", { fg = "#9ece6a", bold = true })
          vim.api.nvim_set_hl(0, "zshDeref", { fg = "#7aa2f7" })
          vim.api.nvim_set_hl(0, "zshOptStart", { fg = "#7dcfff" })
          
          -- Fix for bright red blocks specifically
          vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#414868", bg = "#1a1b26" })
          vim.api.nvim_set_hl(0, "DiffChange", { fg = "#414868", bg = "#1a1b26" })
        end
      })
    end,
  },
  
  -- Load WezTerm integration 
  {
    "nvim-lua/plenary.nvim",
    event = "VeryLazy",
    config = function()
      -- Load our custom WezTerm integration
      local wezterm_ok, wezterm = pcall(require, "integrations.wezterm")
      if wezterm_ok then
        wezterm.setup()
      else
        print("WezTerm integration module not found")
      end
      
      -- Load the smart navigator for seamless pane navigation
      local navigator_ok, navigator = pcall(require, "integrations.wezterm_navigator")
      if navigator_ok then
        navigator.setup()
      else
        print("WezTerm navigator module not found")
      end
    end,
  }
}
