local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
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
        f = {
          name = "Find",
          f = { "<cmd>Telescope find_files<CR>", "Find File" },
          g = { "<cmd>Telescope live_grep<CR>", "Live Grep" },
          b = { "<cmd>Telescope buffers<CR>", "Find Buffer" },
          h = { "<cmd>Telescope help_tags<CR>", "Help Tags" },
        },
        e = {
          name = "Explorer",
          e = { "<cmd>NvimTreeToggle<CR>", "Toggle NvimTree" },
          f = { "<cmd>NvimTreeFindFile<CR>", "Find File in NvimTree" },
          r = { "<cmd>NvimTreeRefresh<CR>", "Refresh NvimTree" },
          c = { "<cmd>NvimTreeCollapse<CR>", "Collapse NvimTree" },
          o = { "<cmd>NvimTreeFocus<CR>", "Focus NvimTree" },
          -- Oil file manager
          o = { "<cmd>Oil<CR>", "Open Oil File Explorer" },
          f = { "<cmd>Oil --float<CR>", "Open Oil in Floating Window" },
        },
        w = {
          name = "Window",
          h = { "<C-w>h", "Move to left window" },
          j = { "<C-w>j", "Move to below window" },
          k = { "<C-w>k", "Move to above window" },
          l = { "<C-w>l", "Move to right window" },
          s = { "<C-w>s", "Split window horizontally" },
          v = { "<C-w>v", "Split window vertically" },
          c = { "<C-w>c", "Close window" },
          o = { "<C-w>o", "Close all other windows" },
        },
        b = {
          name = "Buffer",
          n = { "<cmd>bnext<CR>", "Next buffer" },
          p = { "<cmd>bprevious<CR>", "Previous buffer" },
          d = { "<cmd>bdelete<CR>", "Delete buffer" },
        },
        c = {
          name = "Code",
          c = { function() require("Comment.api").toggle.linewise.current() end, "Toggle Comment" },
          b = { function() require("Comment.api").toggle.blockwise.current() end, "Toggle Block Comment" },
          a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
          r = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename Symbol" },
          f = { "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", "Format Code" },
        },
        h = {
          name = "Hop",
          w = { function() require('hop').hint_words() end, "Hop to Word" },
          l = { function() require('hop').hint_lines() end, "Hop to Line" },
          a = { function() require('hop').hint_anywhere() end, "Hop Anywhere" },
        },
        t = {
          name = "Toggle/Treesitter",
          s = { 
            function()
              local ls = vim.opt.laststatus:get()
              if ls == 0 then
                vim.opt.laststatus = 2
              elseif ls == 2 then
                vim.opt.laststatus = 0
              end
              vim.cmd("redrawstatus")
            end, 
            "Toggle Statusline"
          },
          u = { "<cmd>TSUpdate<CR>", "Update Treesitter Parsers" },
          i = { "<cmd>TSModuleInfo<CR>", "Show Treesitter Module Info" },
        },
        g = {
          name = "Git/Goto",
          s = { "<cmd>Gitsigns stage_hunk<CR>", "Stage Hunk" },
          u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Undo Stage Hunk" },
          r = { "<cmd>Gitsigns reset_hunk<CR>", "Reset Hunk" },
          p = { "<cmd>Gitsigns preview_hunk<CR>", "Preview Hunk" },
          b = { "<cmd>Gitsigns blame_line<CR>", "Blame Line" },
          d = { "<cmd>Gitsigns diffthis<CR>", "Diff This" },
          D = { "<cmd>lua vim.lsp.buf.declaration()<CR>", "Go to Declaration" },
          d = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to Definition" },
          i = { "<cmd>lua vim.lsp.buf.implementation()<CR>", "Go to Implementation" },
          r = { "<cmd>lua vim.lsp.buf.references()<CR>", "Find References" },
        },
        l = {
          name = "LSP",
          i = { "<cmd>LspInfo<CR>", "LSP Info" },
          r = { "<cmd>LspRestart<CR>", "Restart LSP" },
          s = { "<cmd>LspStart<CR>", "Start LSP" },
          S = { "<cmd>LspStop<CR>", "Stop LSP" },
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
    end
  }
}

return M
