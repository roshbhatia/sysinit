local M = {}

M.plugins = {
  {
    "Bekaboo/dropbar.nvim",
    event = "VeryLazy",
    dependencies = {
      -- Optional fuzzy finder integration
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      local dropbar = require("dropbar")
      local utils = require("dropbar.utils")
      local sources = require("dropbar.sources")
      
      dropbar.setup({
        -- Bar appearance and behavior
        bar = {
          -- Attach automatically to buffers
          enable = function(buf, win, _)
            -- Skip if buffer or window is invalid
            if
              not vim.api.nvim_buf_is_valid(buf)
              or not vim.api.nvim_win_is_valid(win)
              or vim.fn.win_gettype(win) ~= ''
              or vim.wo[win].winbar ~= ''
              or vim.bo[buf].ft == 'help'
            then
              return false
            end
            
            -- Skip for large files (1MB+)
            local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
            if stat and stat.size > 1024 * 1024 then
              return false
            end
            
            -- Enable for markdown, LSP, and treesitter
            return vim.bo[buf].ft == 'markdown'
              or pcall(vim.treesitter.get_parser, buf)
              or not vim.tbl_isempty(vim.lsp.get_clients({
                bufnr = buf,
                method = 'textDocument/documentSymbol',
              }))
          end,
          
          -- Update frequency and events
          update_debounce = 100, -- Increased for better performance
          
          -- Sources configuration and fallback
          sources = function(buf, _)
            if vim.bo[buf].ft == 'markdown' then
              return {
                sources.path,
                sources.markdown,
              }
            end
            if vim.bo[buf].ft == 'terminal' then
              return {
                sources.terminal,
              }
            end
            if vim.bo[buf].ft == 'oil' then
              return {
                sources.path,
              }
            end
            return {
              sources.path,
              utils.source.fallback({
                sources.lsp,
                sources.treesitter,
              }),
            }
          end,
          
          -- Visual options
          padding = { left = 1, right = 1 },
          pick = {
            pivots = 'abcdefghijklmnopqrstuvwxyz',
          },
          truncate = true,
          
          -- Hover support
          hover = true,
        },
        
        -- Menu appearance and behavior
        menu = {
          -- Enable quick navigation to prev/next clickable component
          quick_navigation = true,
          
          -- Menu entry padding
          entry = {
            padding = { left = 1, right = 1 },
          },
          
          -- Preview settings
          preview = true,
          hover = true,
          
          -- Window appearance
          win_configs = {
            border = "rounded",
            style = "minimal",
          },
          
          -- Display scrollbar when menu is long
          scrollbar = {
            enable = true,
            background = true,
          },
        },
        
        -- Symbol appearance
        symbol = {
          preview = {
            -- Adjust window position after previewing
            reorient = function(win, range)
              -- Center cursor on screen after preview
              vim.api.nvim_set_current_win(win)
              vim.api.nvim_win_set_cursor(win, {range.start.line + 1, range.start.character})
              vim.cmd("normal! zz")
              vim.api.nvim_win_set_cursor(0, {range.start.line + 1, range.start.character})
            end,
          },
          jump = {
            -- Adjust window position after jumping
            reorient = function(win, range)
              -- Center cursor on screen after jump
              vim.api.nvim_set_current_win(win)
              vim.api.nvim_win_set_cursor(win, {range.start.line + 1, range.start.character})
              vim.cmd("normal! zz")
            end,
          },
        },
        
        -- Source-specific settings
        sources = {
          -- Path source settings
          path = {
            -- Maximum depth of path components to show
            max_depth = 3,
            
            -- Filter function for file entries
            filter = function(name)
              return name ~= "."
            end,
            
            -- Custom filename for modified buffers
            modified = function(sym)
              if vim.bo.modified then
                return sym:merge({
                  name = sym.name .. " [+]",
                  name_hl = "DiffAdd",
                })
              end
              return sym
            end,
          },
          
          -- Treesitter source settings
          treesitter = {
            -- Maximum depth of symbols to show
            max_depth = 16,
          },
          
          -- LSP source settings
          lsp = {
            -- Maximum depth of symbols to show
            max_depth = 16,
          },
        },
      })
    end
  }
}

function M.setup()
  -- Register keymaps with which-key if available
  local status, wk = pcall(require, "which-key")
  if status then
    wk.register({
      ["<leader>d"] = {
        name = "📊 Dropbar",
        ["p"] = { function() require("dropbar.api").pick() end, "Pick Symbols in Winbar" },
        ["g"] = { function() require("dropbar.api").goto_context_start() end, "Go to Context Start" },
        ["n"] = { function() require("dropbar.api").select_next_context() end, "Select Next Context" },
      },
    })
  else
    -- Default keymaps if which-key is not available
    vim.keymap.set('n', '<Leader>dp', function() require('dropbar.api').pick() end, { desc = 'Pick symbols in winbar' })
    vim.keymap.set('n', '<Leader>dg', function() require('dropbar.api').goto_context_start() end, { desc = 'Go to start of current context' })
    vim.keymap.set('n', '<Leader>dn', function() require('dropbar.api').select_next_context() end, { desc = 'Select next context' })
  end

  -- Create highlight link groups to match theme
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      -- Link highlight groups to existing theme highlights for better integration
      vim.api.nvim_set_hl(0, "DropBarCurrentContext", { link = "Visual" })
      vim.api.nvim_set_hl(0, "DropBarIconKindArray", { link = "Operator" })
      vim.api.nvim_set_hl(0, "DropBarIconKindFunction", { link = "Function" })
      vim.api.nvim_set_hl(0, "DropBarIconKindClass", { link = "Type" })
      vim.api.nvim_set_hl(0, "DropBarMenuNormalFloat", { link = "NormalFloat" })
      vim.api.nvim_set_hl(0, "DropBarMenuFloatBorder", { link = "FloatBorder" })
    end,
  })
  
  -- Execute once to set initial highlights
  vim.cmd("doautocmd ColorScheme")
end

return M
