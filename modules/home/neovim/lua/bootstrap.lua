-- Bootstrap file for sysinit.nvim
-- This file initializes the core system and handles plugin management

local M = {}

-- Initialize and load the core system
function M.init()
  -- Initialize core module
  local core = require("core")
  core.init()
  
  -- Return plugin specs for lazy.nvim
  return core.get_plugin_specs()
end

-- Setup and configure lazy.nvim
function M.setup_lazy()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  
  -- Auto-install lazy.nvim if not present
  if not vim.loop.fs_stat(lazypath) then
    vim.notify("Installing lazy.nvim...", vim.log.levels.INFO)
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  
  -- Add lazy.nvim to runtimepath
  vim.opt.rtp:prepend(lazypath)
  
  -- Configure lazy.nvim
  require("lazy").setup(M.init(), {
    install = {
      colorscheme = { "gruvbox", "habamax" },
    },
    ui = {
      border = "rounded",
      icons = {
        cmd = " ",
        config = " ",
        event = " ",
        ft = " ",
        init = " ",
        keys = " ",
        plugin = " ",
        runtime = " ",
        source = " ",
        start = " ",
        task = " ",
        lazy = "󰒲 ",
      },
    },
    change_detection = {
      notify = false,
    },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  })
end

-- Configure global options
function M.setup_options()
  -- Basic editor settings
  vim.g.mapleader = " "
  vim.g.maplocalleader = ","
  
  -- UI settings
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.cursorline = true
  vim.opt.signcolumn = "yes"
  vim.opt.termguicolors = true
  vim.opt.showmode = false
  
  -- Search settings
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  
  -- Editing experience
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true
  
  -- Splits and windows
  vim.opt.splitbelow = true
  vim.opt.splitright = true
  
  -- Backups and swapfiles
  vim.opt.backup = false
  vim.opt.writebackup = false
  vim.opt.swapfile = false
  vim.opt.undofile = true
  vim.opt.undodir = vim.fn.stdpath("state") .. "/undodir"
  
  -- Better clipboard handling
  vim.opt.clipboard = "unnamedplus"
  
  -- Performance options
  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300
  vim.opt.lazyredraw = true
  
  -- Scrolling
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  
  -- Folding (using treesitter)
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  vim.opt.foldenable = false  -- Disable folding by default
  vim.opt.foldlevel = 99
  
  -- Mouse support
  vim.opt.mouse = "a"
  
  -- Command line
  vim.opt.cmdheight = 1
  vim.opt.showmatch = true
  
  -- Global statusline
  vim.opt.laststatus = 3
  
  -- Enable 24-bit colors
  vim.opt.termguicolors = true
  
  -- Hidden buffers (allow buffer switching without saving)
  vim.opt.hidden = true
  
  -- Complete options
  vim.opt.completeopt = { "menuone", "noselect" }
  
  -- Diagnostics signs
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end
end

-- Register autocommands
function M.setup_autocommands()
  local augroup = vim.api.nvim_create_augroup("SysinitAutocmds", { clear = true })
  
  -- Highlight yanked text
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup,
    callback = function()
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
    end,
  })
  
  -- Return to last edit position when opening files
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function()
      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local line_count = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= line_count then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
  })
  
  -- Auto resize splits when window is resized
  vim.api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
      vim.cmd("tabdo wincmd =")
    end,
  })
  
  -- Close certain filetypes with just q
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = {
      "qf",
      "help",
      "man",
      "notify",
      "lspinfo",
      "spectre_panel",
      "startuptime",
      "tsplayground",
      "PlenaryTestPopup",
    },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
  })
  
  -- Disable diagnostics in certain files
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "gitcommit", "markdown", "text", "txt" },
    callback = function()
      vim.diagnostic.disable(0)
    end,
  })
  
  -- Set wrap and spell in certain files
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "gitcommit", "markdown", "text", "txt" },
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.spell = true
    end,
  })
end

-- Bootstrap system
function M.bootstrap()
  -- Start with global options
  M.setup_options()
  
  -- Setup autocommands
  M.setup_autocommands()
  
  -- Setup lazy.nvim and load plugins
  M.setup_lazy()
  
  -- Setup colorscheme (will be handled by the theme module later)
  vim.cmd("colorscheme gruvbox")
  
  -- Show success message
  vim.notify("Sysinit loaded successfully", vim.log.levels.INFO)
  
  -- Register startup time command
  vim.api.nvim_create_user_command("StartupTime", function()
    vim.cmd("Lazy profile")
  end, {})
  
  -- Register SysinitDocs command
  vim.api.nvim_create_user_command("SysinitDocs", function()
    local core = require("core")
    local modules = core.modules
    
    local lines = {"# Sysinit Documentation", "", "## Available Modules"}
    
    for name, module in pairs(modules) do
      table.insert(lines, "")
      table.insert(lines, "### " .. name)
      
      -- Add module dependencies
      if module.depends_on and #module.depends_on > 0 then
        table.insert(lines, "")
        table.insert(lines, "Dependencies: " .. table.concat(module.depends_on, ", "))
      end
      
      -- Add plugin count
      if module.plugins and #module.plugins > 0 then
        table.insert(lines, "")
        table.insert(lines, "Plugins: " .. #module.plugins)
        
        -- List major plugins
        table.insert(lines, "")
        table.insert(lines, "Major plugins:")
        for _, plugin in ipairs(module.plugins) do
          if type(plugin) == "table" and type(plugin[1]) == "string" then
            local name = plugin[1]:match("^.+/(.+)$") or plugin[1]
            table.insert(lines, "- " .. name)
          end
        end
      end
      
      -- Add module verification steps
      local verify = require("core.verify")
      if verify.verifications[name] then
        table.insert(lines, "")
        table.insert(lines, "Verification steps:")
        for _, step in ipairs(verify.verifications[name]) do
          table.insert(lines, "- " .. step.desc .. ": " .. step.expected)
        end
      end
    end
    
    -- Create documentation buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    
    -- Show in new tab
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, buf)
    
    -- Set buffer options
    vim.api.nvim_buf_set_name(buf, "SysinitDocs")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    
    -- Set mappings
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":tabclose<CR>", { noremap = true, silent = true })
  end, {})
end

return M