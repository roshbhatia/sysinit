-- UI related plugins

-- Import individual UI components
local symbols_outline = require("plugins.ui.symbols-outline")
local bufferline = require("plugins.ui.bufferline")

return {
  symbols_outline,
  bufferline,
  
  -- Colorschemes
  -- Tokyo Night theme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
        },
      })
    end,
  },
  
  -- Catppuccin theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        integrations = {
          cmp = true,
          gitsigns = true,
          telescope = true,
          which_key = true,
          navic = {
            enabled = true,
            custom_bg = "NONE",
          },
        },
      })
    end,
  },
  
  -- GitHub theme
  {
    "projekt0n/github-nvim-theme",
    lazy = true,
    config = function()
      require("github-theme").setup({})
    end,
  },
  
  -- Kanagawa theme
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    config = function()
      require("kanagawa").setup({
        compile = true,
        dimInactive = true,
      })
    end,
  },
  
  -- Theme switcher
  {
    "zaldih/themery.nvim",
    cmd = "Themery",
    keys = {
      { "<leader>tt", ":Themery<CR>", desc = "Change Theme" },
    },
    config = function()
      require("themery").setup({
        themes = {
          { name = "Tokyo Night", colorscheme = "tokyonight" },
          { name = "Tokyo Night Storm", colorscheme = "tokyonight-storm" },
          { name = "Catppuccin Mocha", colorscheme = "catppuccin" },
          { name = "Catppuccin Macchiato", colorscheme = "catppuccin-macchiato" },
          { name = "GitHub Dark", colorscheme = "github_dark" },
          { name = "GitHub Light", colorscheme = "github_light" },
          { name = "Kanagawa", colorscheme = "kanagawa" },
        },
        themeConfigFile = vim.fn.stdpath("config") .. "/lua/core/theme.lua",
        livePreview = true,
      })
    end,
  },
  
  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  
  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { enabled = true },
      exclude = {
        filetypes = {
          "help",
          "startify",
          "dashboard",
          "lazy",
          "neogitstatus",
          "NvimTree",
          "Trouble",
          "text",
        },
      },
    },
  },
  
  -- Highlights
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "css", "go", "html", "java", "javascript", 
          "json", "lua", "markdown", "markdown_inline", "python", "regex", 
          "rust", "tsx", "typescript", "vim", "vimdoc", "yaml",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
  
  -- Improved UI components
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    config = function()
      require("dressing").setup({
        input = {
          enabled = true,
          default_prompt = "Input:",
          prompt_align = "left",
          insert_only = true,
          border = "rounded",
          relative = "cursor",
          prefer_width = 40,
          width = nil,
          max_width = { 140, 0.9 },
          min_width = { 20, 0.2 },
          win_options = {
            winblend = 10,
            winhighlight = "",
          },
          mappings = {
            n = {
              ["<Esc>"] = "Close",
              ["<CR>"] = "Confirm",
            },
            i = {
              ["<C-c>"] = "Close",
              ["<CR>"] = "Confirm",
              ["<Up>"] = "HistoryPrev",
              ["<Down>"] = "HistoryNext",
            },
          },
        },
        select = {
          enabled = true,
          backend = { "telescope", "fzf", "builtin" },
          trim_prompt = true,
          border = "rounded",
          relative = "cursor",
          win_options = {
            winblend = 10,
            winhighlight = "",
          },
          get_config = nil,
        },
      })
    end,
  },
  
  -- Notifications
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      require("notify").setup({
        background_colour = "#000000",
        timeout = 3000,
        max_width = 50,
        max_height = 10,
        stages = "fade",
        render = "default",
      })
      vim.notify = require("notify")
    end,
  },
  
  -- Improved UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      })
    end,
  },
  
  -- (Zen mode and Twilight removed as requested)
  
  -- Heirline for statusline
  {
    "rebelot/heirline.nvim",
    event = "UIEnter",
    config = function()
      -- Minimal Heirline setup
      local conditions = require("heirline.conditions")
      local utils = require("heirline.utils")
      
      -- Colors
      local colors = {
        bright_bg = utils.get_highlight("Folded").bg,
        bright_fg = utils.get_highlight("Folded").fg,
        red = utils.get_highlight("DiagnosticError").fg,
        dark_red = utils.get_highlight("DiffDelete").bg,
        green = utils.get_highlight("String").fg,
        blue = utils.get_highlight("Function").fg,
        gray = utils.get_highlight("NonText").fg,
        orange = utils.get_highlight("Constant").fg,
        purple = utils.get_highlight("Statement").fg,
        cyan = utils.get_highlight("Special").fg,
        diag_warn = utils.get_highlight("DiagnosticWarn").fg,
        diag_error = utils.get_highlight("DiagnosticError").fg,
        diag_hint = utils.get_highlight("DiagnosticHint").fg,
        diag_info = utils.get_highlight("DiagnosticInfo").fg,
        git_del = utils.get_highlight("DiffDelete").fg,
        git_add = utils.get_highlight("DiffAdd").fg,
        git_change = utils.get_highlight("DiffChange").fg,
      }
      
      -- Mode Colors
      local mode_colors = {
        n = colors.blue,
        i = colors.green,
        v = colors.purple,
        V = colors.purple,
        ["\22"] = colors.purple,
        c = colors.orange,
        s = colors.purple,
        S = colors.purple,
        ["\19"] = colors.purple,
        R = colors.red,
        r = colors.red,
        ["!"] = colors.red,
        t = colors.green,
      }
      
      -- Components
      local ViMode = {
        init = function(self)
          self.mode = vim.fn.mode(1)
        end,
        static = {
          mode_names = {
            n = "NORMAL",
            no = "OP-PENDING",
            nov = "OP-PENDING",
            noV = "OP-PENDING",
            ["no\22"] = "OP-PENDING",
            niI = "NORMAL",
            niR = "NORMAL",
            niV = "NORMAL",
            nt = "NORMAL",
            v = "VISUAL",
            vs = "VISUAL",
            V = "V-LINE",
            Vs = "V-LINE",
            ["\22"] = "V-BLOCK",
            ["\22s"] = "V-BLOCK",
            s = "SELECT",
            S = "S-LINE",
            ["\19"] = "S-BLOCK",
            i = "INSERT",
            ic = "INSERT",
            ix = "INSERT",
            R = "REPLACE",
            Rc = "REPLACE",
            Rx = "REPLACE",
            Rv = "V-REPLACE",
            Rvc = "V-REPLACE",
            Rvx = "V-REPLACE",
            c = "COMMAND",
            cv = "EX",
            r = "REPLACE",
            rm = "MORE",
            ["r?"] = "CONFIRM",
            ["!"] = "SHELL",
            t = "TERMINAL",
          },
        },
        hl = function(self)
          return { fg = mode_colors[self.mode:sub(1, 1)], bold = true }
        end,
        {
          provider = function(self)
            return " %2(" .. self.mode_names[self.mode] .. "%)"
          end,
        },
      }
      
      local FileInfo = {
        {
          provider = function()
            local filename = vim.fn.expand("%:t")
            local extension = vim.fn.expand("%:e")
            local icon = require("nvim-web-devicons").get_icon(filename, extension)
            if icon then
              return icon .. " " .. filename
            else
              return filename
            end
          end,
          hl = { fg = utils.get_highlight("Directory").fg },
        },
        {
          provider = function()
            local readonly = vim.api.nvim_buf_get_option(0, "readonly")
            local modified = vim.api.nvim_buf_get_option(0, "modified")
            
            if readonly then
              return " 󰌾"
            elseif modified then
              return " 󰝨"
            else
              return ""
            end
          end,
          hl = { fg = colors.orange },
        },
      }
      
      local WorkDir = {
        provider = function()
          local cwd = vim.fn.getcwd(0)
          cwd = vim.fn.fnamemodify(cwd, ":~")
          return " 󰉋 " .. cwd .. " "
        end,
        hl = { fg = colors.blue, bold = true },
      }
      
      local Diagnostics = {
        condition = conditions.has_diagnostics,
        init = function(self)
          self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
          self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
          self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
          self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
        end,
        update = { "DiagnosticChanged", "BufEnter" },
        {
          provider = function(self)
            return self.errors > 0 and (" 󰅚 " .. self.errors)
          end,
          hl = { fg = colors.diag_error },
        },
        {
          provider = function(self)
            return self.warnings > 0 and (" 󰀪 " .. self.warnings)
          end,
          hl = { fg = colors.diag_warn },
        },
        {
          provider = function(self)
            return self.info > 0 and (" 󰋽 " .. self.info)
          end,
          hl = { fg = colors.diag_info },
        },
        {
          provider = function(self)
            return self.hints > 0 and (" 󰌶 " .. self.hints)
          end,
          hl = { fg = colors.diag_hint },
        },
      }
      
      local Git = {
        condition = conditions.is_git_repo,
        init = function(self)
          self.status_dict = vim.b.gitsigns_status_dict
          self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
        end,
        {
          provider = function(self)
            return " 󰊢 " .. self.status_dict.head .. " "
          end,
          hl = { fg = colors.orange, bold = true },
        },
        {
          provider = function(self)
            if self.status_dict.added and self.status_dict.added > 0 then
              return " +" .. self.status_dict.added
            end
          end,
          hl = { fg = colors.git_add },
        },
        {
          provider = function(self)
            if self.status_dict.changed and self.status_dict.changed > 0 then
              return " ~" .. self.status_dict.changed
            end
          end,
          hl = { fg = colors.git_change },
        },
        {
          provider = function(self)
            if self.status_dict.removed and self.status_dict.removed > 0 then
              return " -" .. self.status_dict.removed
            end
          end,
          hl = { fg = colors.git_del },
        },
      }
      
      local FileType = {
        provider = function()
          return vim.bo.filetype
        end,
        hl = { fg = colors.gray, bold = true },
      }
      
      local Ruler = {
        provider = "%7(%l/%3L%):%2c %P",
        hl = { fg = colors.bright_fg },
      }
      
      local LSPActive = {
        condition = conditions.lsp_attached,
        update = { "LspAttach", "LspDetach" },
        provider = function()
          local names = {}
          for _, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
          end
          return " 󰒓 [" .. table.concat(names, " ") .. "]"
        end,
        hl = { fg = colors.green, bold = true },
      }
      
      local Align = { provider = "%=" }
      local Space = { provider = " " }
      
      local statusline = {
        ViMode, Space, WorkDir, FileInfo, Space, Git, Space, Diagnostics, Align,
        LSPActive, Space, FileType, Space, Ruler, Space,
      }
      
      require("heirline").setup({
        statusline = statusline,
        winbar = nil,  -- No winbar for simplicity
        opts = {
          colors = colors,
          disable_winbar_cb = function()
            return true  -- Disable winbar for now
          end,
        },
      })
    end,
  },
  
  -- Better folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open All Folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close All Folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek Fold" },
    },
    config = function()
      vim.o.foldcolumn = "0"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      
      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
        fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}
          local suffix = ("  %d lines"):format(endLnum - lnum)
          local sufWidth = vim.fn.strdisplaywidth(suffix)
          local targetWidth = width - sufWidth
          local curWidth = 0
          
          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            
            if targetWidth > curWidth + chunkWidth then
              table.insert(newVirtText, chunk)
            else
              chunkText = truncate(chunkText, targetWidth - curWidth)
              local hlGroup = chunk[2]
              table.insert(newVirtText, { chunkText, hlGroup })
              chunkWidth = vim.fn.strdisplaywidth(chunkText)
              
              if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
              end
              break
            end
            curWidth = curWidth + chunkWidth
          end
          
          table.insert(newVirtText, { suffix, "Comment" })
          return newVirtText
        end,
      })
    end,
  },
  
  -- Better search experience
  {
    "kevinhwang91/nvim-hlslens",
    keys = {
      { "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]] },
      { "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]] },
      { "*", [[*<Cmd>lua require('hlslens').start()<CR>]] },
      { "#", [[#<Cmd>lua require('hlslens').start()<CR>]] },
      { "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]] },
      { "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]] },
    },
    config = function()
      require("hlslens").setup({
        calm_down = true,
        nearest_only = false,
        nearest_float_when = "always",
        float_shadow_blend = 50,
        virt_priority = 100,
        build_position_cb = function(plist, _, _, _)
          require("scrollbar.handlers.search").handler.show(plist.start_pos)
        end,
      })
    end,
  },
  
  -- Minimap (for code overview)
  {
    "gorbit99/codewindow.nvim",
    event = "BufReadPre",
    keys = {
      { "<leader>tm", "<cmd>lua require('codewindow').toggle_minimap()<CR>", desc = "Toggle Minimap" },
    },
    config = function()
      local codewindow = require('codewindow')
      codewindow.setup({
        active_in_terminals = false,
        auto_enable = false,
        exclude_filetypes = { 'help', 'startify', 'dashboard', 'lazy' },
        max_minimap_height = nil,
        max_lines = nil,
        minimap_width = 15,
        use_lsp = true,
        use_treesitter = true,
        use_git = true,
        width_multiplier = 4,
        z_index = 10,
        show_cursor = true,
        window_border = 'single',
      })
    end,
  },
  
  -- Scrollbar
  {
    "petertriho/nvim-scrollbar",
    event = "BufReadPost",
    config = function()
      require("scrollbar").setup({
        show = true,
        show_in_active_only = true,
        set_highlights = true,
        folds = 1000, -- handle folds, set to number to disable folds if no. of lines in buffer exceeds this
        max_lines = false, -- disables if no. of lines in buffer exceeds this
        hide_if_all_visible = false, -- Hides everything if all lines are visible
        throttle_ms = 100,
        handle = {
          text = " ",
          color = nil,
          color_nr = nil, -- cterm
          highlight = "CursorColumn",
          hide_if_all_visible = true, -- Hides handle if all lines are visible
        },
        marks = {
          Search = {
            text = { "-", "=" },
            priority = 0,
            color = nil,
            cterm = nil,
            highlight = "Search",
          },
          Error = {
            text = { "-", "=" },
            priority = 1,
            color = nil,
            cterm = nil,
            highlight = "DiagnosticVirtualTextError",
          },
          Warn = {
            text = { "-", "=" },
            priority = 2,
            color = nil,
            cterm = nil,
            highlight = "DiagnosticVirtualTextWarn",
          },
          Info = {
            text = { "-", "=" },
            priority = 3,
            color = nil,
            cterm = nil,
            highlight = "DiagnosticVirtualTextInfo",
          },
          Hint = {
            text = { "-", "=" },
            priority = 4,
            color = nil,
            cterm = nil,
            highlight = "DiagnosticVirtualTextHint",
          },
          Misc = {
            text = { "-", "=" },
            priority = 5,
            color = nil,
            cterm = nil,
            highlight = "Normal",
          },
        },
        excluded_buftypes = {
          "terminal",
          "prompt",
        },
        excluded_filetypes = {
          "prompt",
          "TelescopePrompt",
          "noice",
          "Outline",
          "CHADTree",
        },
        autocmd = {
          render = {
            "BufWinEnter",
            "TabEnter",
            "TermEnter",
            "WinEnter",
            "CmdwinLeave",
            "TextChanged",
            "VimResized",
            "WinScrolled",
          },
          clear = {
            "BufWinLeave",
            "TabLeave",
            "TermLeave",
            "WinLeave",
          },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true,
          handle = true,
          search = true,
        },
      })
    end,
  },
}