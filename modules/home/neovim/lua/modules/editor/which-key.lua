local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
    end
  }
}

function M.setup()
  local wk = require("which-key")
  
  wk.setup({
        plugins = {
          marks = true,      -- shows a list of your marks on ' and `
          registers = true,  -- shows your registers on " in NORMAL or <C-r> in INSERT mode
          spelling = {
            enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
            suggestions = 20,
          },
          presets = {
            operators = true,    -- adds help for operators like d, y, ...
            motions = true,      -- adds help for motions
            text_objects = true, -- help for text objects triggered after entering an operator
            windows = true,      -- default bindings on <c-w>
            nav = true,          -- misc bindings to work with windows
            z = true,            -- bindings for folds, spelling and others prefixed with z
            g = true,            -- bindings for prefixed with g
          },
        },
        window = {
          border = "rounded",       -- none, single, double, shadow
          position = "bottom",      -- bottom, top
          margin = { 1, 0, 1, 0 },  -- extra window margin [top, right, bottom, left]
          padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
        },
        layout = {
          height = { min = 4, max = 25 },                                    -- min and max height of the columns
          width = { min = 20, max = 50 },                                    -- min and max width of the columns
          spacing = 3,                                                       -- spacing between columns
          align = "left",                                                    -- align columns left, center or right
        },
        ignore_missing = false,                                              -- enable this to hide mappings for which you didn't specify a label
        hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
        show_help = true,                                                    -- show help message on the command line when the popup is visible
        triggers = "auto",                                                   -- automatically setup triggers setup triggers
      })

      -- Define leader key groups
      wk.register({
        -- Find group (search related operations)
        f = {
          name = "🔍 Find",
          f = { "<cmd>Telescope find_files<CR>", "Find Files" },
          g = { "<cmd>Telescope live_grep<CR>", "Live Grep" },
          b = { "<cmd>Telescope buffers<CR>", "Find Buffers" },
          h = { "<cmd>Telescope help_tags<CR>", "Help Tags" },
          r = { "<cmd>Telescope oldfiles<CR>", "Recent Files" },
          c = { "<cmd>Telescope commands<CR>", "Commands" },
          k = { "<cmd>Telescope keymaps<CR>", "Keymaps" },
          s = { "<cmd>Telescope grep_string<CR>", "Search Current Word" },
          p = { "<cmd>Telescope projects<CR>", "Projects" },
          t = { "<cmd>Telescope<CR>", "Open Telescope" },
          m = { "<cmd>Telescope marks<CR>", "Marks" },
        },
        
        -- Explorer group (file managers)
        e = {
          name = "📁 Explorer",
          -- NvimTree commands
          n = { "<cmd>NvimTreeToggle<CR>", "Toggle NvimTree" },
          f = { "<cmd>NvimTreeFindFile<CR>", "Find in NvimTree" },
          r = { "<cmd>NvimTreeRefresh<CR>", "Refresh NvimTree" },
          c = { "<cmd>NvimTreeCollapse<CR>", "Collapse NvimTree" },
          -- Oil commands
          o = { "<cmd>Oil<CR>", "Open Oil" },
          i = { "<cmd>Oil --float<CR>", "Oil in Float Window" },
        },
        
        -- Window management
        w = {
          name = "🪟 Window",
          -- Navigation
          h = { "<C-w>h", "Go Left" },
          j = { "<C-w>j", "Go Down" },
          k = { "<C-w>k", "Go Up" },
          l = { "<C-w>l", "Go Right" },
          -- Splitting
          s = { "<C-w>s", "Split Horizontal" },
          v = { "<C-w>v", "Split Vertical" },
          -- Window operations
          c = { "<C-w>c", "Close Window" },
          o = { "<C-w>o", "Only This Window" },
          -- Resizing
          ["+"] = { "<cmd>resize +5<CR>", "Increase Height" },
          ["-"] = { "<cmd>resize -5<CR>", "Decrease Height" },
          [">"] = { "<cmd>vertical resize +5<CR>", "Increase Width" },
          ["<"] = { "<cmd>vertical resize -5<CR>", "Decrease Width" },
          ["="] = { "<C-w>=", "Equal Size" },
          -- Moving windows
          H = { "<C-w>H", "Move Window Left" },
          J = { "<C-w>J", "Move Window Down" },
          K = { "<C-w>K", "Move Window Up" },
          L = { "<C-w>L", "Move Window Right" },
        },
        
        -- Buffer management
        b = {
          name = "📝 Buffer",
          n = { "<cmd>bnext<CR>", "Next Buffer" },
          p = { "<cmd>bprevious<CR>", "Previous Buffer" },
          d = { "<cmd>bdelete<CR>", "Delete Buffer" },
          f = { "<cmd>bfirst<CR>", "First Buffer" },
          l = { "<cmd>blast<CR>", "Last Buffer" },
          s = { "<cmd>Telescope buffers<CR>", "Search Buffers" },
          h = { "<cmd>Telescope oldfiles<CR>", "Buffer History" },
          o = { "<cmd>%bd|e#|bd#<CR>", "Close Others" },
          a = { "<cmd>%bd<CR>", "Close All" },
        },
        
        -- Code actions
        c = {
          name = "💡 Code",
          -- Comments
          c = { function() require("Comment.api").toggle.linewise.current() end, "Toggle Comment" },
          b = { function() require("Comment.api").toggle.blockwise.current() end, "Block Comment" },
          -- LSP actions
          a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
          r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename Symbol" },
          f = { "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", "Format Code" },
          d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to Definition" },
          D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Go to Declaration" },
          i = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Go to Implementation" },
          s = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help" },
          t = { "<cmd>lua vim.lsp.buf.type_definition()<CR>", "Type Definition" },
          h = { "<cmd>lua vim.lsp.buf.hover()<CR>", "Hover Documentation" },
          n = { "<cmd>lua vim.diagnostic.goto_next()<CR>", "Next Diagnostic" },
          p = { "<cmd>lua vim.diagnostic.goto_prev()<CR>", "Previous Diagnostic" },
          l = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Line Diagnostics" },
        },
        
        -- Hop (quick navigation)
        h = {
          name = "⏩ Hop",
          w = { function() require('hop').hint_words() end, "Hop to Word" },
          l = { function() require('hop').hint_lines() end, "Hop to Line" },
          a = { function() require('hop').hint_anywhere() end, "Hop Anywhere" },
          p = { function() require('hop').hint_patterns() end, "Hop to Pattern" },
          c = { function() require('hop').hint_char1() end, "Hop to Char" },
        },
        
        -- Terminal and toggles
        t = {
          name = "⚙️ Toggle/Terminal",
          -- Status toggles
          s = { function()
                 local ls = vim.opt.laststatus:get()
                 if ls == 0 then
                   vim.opt.laststatus = 2
                 elseif ls == 2 then
                   vim.opt.laststatus = 0
                 end
                 vim.cmd("redrawstatus")
               end, 
               "Toggle Statusline" },
          n = { "<cmd>set number!<CR>", "Toggle Line Numbers" },
          r = { "<cmd>set relativenumber!<CR>", "Toggle Relative Numbers" },
          w = { "<cmd>set wrap!<CR>", "Toggle Wrap" },
          h = { "<cmd>nohlsearch<CR>", "Clear Search Highlight" },
          -- Treesitter
          u = { "<cmd>TSUpdate<CR>", "Update Treesitter" },
          i = { "<cmd>TSModuleInfo<CR>", "Treesitter Info" },
          -- Terminal
          t = { "<cmd>terminal<CR>", "Open Terminal" },
          v = { "<cmd>vsplit | terminal<CR>", "Terminal in VSplit" },
          h = { "<cmd>split | terminal<CR>", "Terminal in HSplit" },
        },
        
        -- Neoscroll settings
        n = {
          name = "🔄 Neoscroll",
          t = { function() vim.g.neoscroll_no_mappings = not vim.g.neoscroll_no_mappings end, "Toggle Neoscroll" },
          e = { function() 
                 local easing = vim.fn.input("Easing function (linear/quadratic/cubic/quartic/quintic/circular/sine): ")
                 if easing ~= "" and neoscroll then
                   neoscroll.setup({ easing = easing })
                   print("Neoscroll easing set to: " .. easing)
                 end
               end, 
               "Change Easing Function" },
          d = { function()
                 local duration = tonumber(vim.fn.input("Duration multiplier: "))
                 if duration and neoscroll then
                   neoscroll.setup({ duration_multiplier = duration })
                   print("Neoscroll duration multiplier set to: " .. duration)
                 end
               end,
               "Change Duration" },
          p = { function()
                 if neoscroll then
                   local mode = not neoscroll.config.performance_mode
                   neoscroll.setup({ performance_mode = mode })
                   print("Neoscroll performance mode: " .. (mode and "on" or "off"))
                 end
               end,
               "Toggle Performance Mode" },
        },
        
        -- Git operations
        g = {
          name = "🔄 Git",
          -- Gitsigns
          s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage Hunk" },
          u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Undo Stage Hunk" },
          r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset Hunk" },
          R = { "<cmd>Gitsigns reset_buffer<CR>", "Reset Buffer" },
          p = { "<cmd>Gitsigns preview_hunk<CR>", "Preview Hunk" },
          b = { "<cmd>Gitsigns blame_line<CR>", "Blame Line" },
          d = { "<cmd>Gitsigns diffthis<CR>", "Diff This" },
          -- Navigation
          n = { "<cmd>Gitsigns next_hunk<CR>", "Next Hunk" },
          N = { "<cmd>Gitsigns prev_hunk<CR>", "Previous Hunk" },
          -- Additional git operations
          S = { "<cmd>Telescope git_status<CR>", "Git Status" },
          c = { "<cmd>Telescope git_commits<CR>", "Git Commits" },
          C = { "<cmd>Telescope git_bcommits<CR>", "Buffer Commits" },
          B = { "<cmd>Telescope git_branches<CR>", "Git Branches" },
        },
        
        -- LSP operations
        l = {
          name = "🔧 LSP",
          i = { "<cmd>LspInfo<CR>", "LSP Info" },
          r = { "<cmd>LspRestart<CR>", "Restart LSP" },
          s = { "<cmd>LspStart<CR>", "Start LSP" },
          S = { "<cmd>LspStop<CR>", "Stop LSP" },
          f = { "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", "Format" },
          a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
          l = { "<cmd>lua vim.lsp.codelens.run()<CR>", "CodeLens Action" },
          d = { "<cmd>Telescope diagnostics bufnr=0<CR>", "Document Diagnostics" },
          w = { "<cmd>Telescope diagnostics<CR>", "Workspace Diagnostics" },
          q = { "<cmd>lua vim.diagnostic.setloclist()<CR>", "Quickfix Diagnostics" },
          m = { "<cmd>Mason<CR>", "Mason" },
        },
        
        -- Wezterm integration
        z = {
          name = "🖥️ WezTerm",
          t = { "<cmd>WeztermSpawn htop<CR>", "Spawn Htop" },
          s = { "<cmd>WeztermSplitPane<CR>", "Split Pane" },
        },
      }, { prefix = "<leader>" })
      
      -- Add text object descriptions
      wk.register({
        ["af"] = { name = "Around Function" },
        ["if"] = { name = "Inside Function" },
        ["ac"] = { name = "Around Class" },
        ["ic"] = { name = "Inside Class" },
        ["ab"] = { name = "Around Block" },
        ["ib"] = { name = "Inside Block" },
        ["ap"] = { name = "Around Paragraph" },
        ["ip"] = { name = "Inside Paragraph" },
      }, { mode = "o" })
      
      -- Add Treesitter navigation mappings
      wk.register({
        ["]f"] = "Next Function Start",
        ["]c"] = "Next Class Start",
        ["]F"] = "Next Function End",
        ["]C"] = "Next Class End",
        ["[f"] = "Previous Function Start",
        ["[c"] = "Previous Class Start",
        ["[F"] = "Previous Function End",
        ["[C"] = "Previous Class End",
      }, { mode = "n" })
      
      -- Add VSCode-like keymaps (will work when using vscode-neovim)
      if vim.g.vscode then
        wk.register({
          f = {
            name = "🔍 Find",
            f = { "<cmd>call VSCodeNotify('workbench.action.quickOpen')<CR>", "Find Files" },
            g = { "<cmd>call VSCodeNotify('workbench.action.findInFiles')<CR>", "Find in Files" },
            s = { "<cmd>call VSCodeNotify('actions.find')<CR>", "Search in File" },
          },
          e = {
            name = "📁 Explorer",
            e = { "<cmd>call VSCodeNotify('workbench.view.explorer')<CR>", "Toggle Explorer" },
            f = { "<cmd>call VSCodeNotify('revealInExplorer')<CR>", "Reveal in Explorer" },
          },
          g = {
            name = "🔄 Git",
            s = { "<cmd>call VSCodeNotify('workbench.view.scm')<CR>", "Source Control" },
            b = { "<cmd>call VSCodeNotify('gitlens.toggleFileBlame')<CR>", "Toggle Blame" },
            d = { "<cmd>call VSCodeNotify('workbench.view.debug')<CR>", "Debug" },
          },
          c = {
            name = "💡 Code",
            a = { "<cmd>call VSCodeNotify('editor.action.quickFix')<CR>", "Code Actions" },
            r = { "<cmd>call VSCodeNotify('editor.action.rename')<CR>", "Rename Symbol" },
            f = { "<cmd>call VSCodeNotify('editor.action.formatDocument')<CR>", "Format Document" },
          },
          w = {
            name = "🪟 Window",
            w = { "<cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>", "Close Window" },
            h = { "<cmd>call VSCodeNotify('workbench.action.navigateLeft')<CR>", "Left Window" },
            j = { "<cmd>call VSCodeNotify('workbench.action.navigateDown')<CR>", "Down Window" },
            k = { "<cmd>call VSCodeNotify('workbench.action.navigateUp')<CR>", "Up Window" },
            l = { "<cmd>call VSCodeNotify('workbench.action.navigateRight')<CR>", "Right Window" },
          },
          b = {
            name = "📝 Buffer",
            n = { "<cmd>call VSCodeNotify('workbench.action.nextEditor')<CR>", "Next Buffer" },
            p = { "<cmd>call VSCodeNotify('workbench.action.previousEditor')<CR>", "Previous Buffer" },
            c = { "<cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>", "Close Buffer" },
          },
        }, { prefix = "<leader>" })
      end
    end
  }
}

function M.setup()
  require("which-key").register(
    {
      -- Quick text object descriptions for non-leader maps
      ["\""] = "Quotes",
      ["'"] = "Single quotes",
      ["`"] = "Backticks",
      ["("] = "Parentheses",
      [")"] = "Parentheses",
      ["{"] = "Braces",
      ["}"] = "Braces",
      ["["] = "Brackets",
      ["]"] = "Brackets",
      ["<"] = "Angle brackets",
      [">"] = "Angle brackets",
      
      -- Navigation
      ["{{"] = "Previous paragraph",
      ["}}"] = "Next paragraph",
    }
  )
end

return M
