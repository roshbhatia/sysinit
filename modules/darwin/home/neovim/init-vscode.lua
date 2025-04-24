-- Mark this as a VSCode instance
vim.g.vscode = true

-- Add debug log function
local function debug_log(msg, level)
  level = level or vim.log.levels.INFO
  -- Create a debug.log file in the Neovim data directory
  local log_path = vim.fn.stdpath("data") .. "/vscode-neovim-debug.log"
  local log_file = io.open(log_path, "a")
  if log_file then
    log_file:write(os.date("%Y-%m-%d %H:%M:%S ") .. msg .. "\n")
    log_file:close()
  end
  
  -- Also use Vim's notify system if available
  vim.notify(msg, level)
end

debug_log("Starting VSCode Neovim initialization")

local function setup_lazy()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git", "clone", "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Add lua directory to runtime path
  local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
  local lua_dir = init_dir .. "/lua"
  vim.opt.rtp:prepend(lua_dir)
end

-- Basic leader setup
local function setup_leader()
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  -- Prevent space from moving cursor in normal/visual mode
  vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })
end

-- Common Neovim settings
local function setup_common_settings()
  -- Search settings
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- Indentation settings
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true

  -- Window behavior
  vim.opt.splitbelow = true
  vim.opt.splitright = true

  -- Performance and usability
  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"
end

-- VSCode integration specific settings
local function setup_vscode_integration()
  if not vim.g.vscode then return end
  -- Suppress VimEnter autocommands to avoid premature remote plugin bootstrap errors
  vim.cmd("set eventignore+=VimEnter")
  vim.notify("VSCode Neovim integration detected", vim.log.levels.INFO)
end

-- Initialize module loader and setup plugins
local function setup_plugins()
  debug_log("Setting up plugins")
  local ok, module_loader = pcall(require, "core.vsc_module_loader")
  if not ok then
    debug_log("Failed to load core.vsc_module_loader: " .. tostring(module_loader), vim.log.levels.ERROR)
    
    -- Try to create the module loader if it doesn't exist
    debug_log("Attempting to create fallback module loader")
    
    -- Create a simple fallback module loader
    local fallback_loader = {}
    
    function fallback_loader.get_plugin_specs(modules)
      debug_log("Using fallback get_plugin_specs")
      return {
        {
          "vscode-neovim/vscode-neovim",
          cond = function() return vim.g.vscode == true end,
          event = "VimEnter",
        }
      }
    end
    
    function fallback_loader.setup_modules(modules)
      debug_log("Using fallback setup_modules")
      
      -- Setup mode display
      vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = function()
          local vscode_ok, vscode = pcall(require, "vscode")
          if not vscode_ok then
            debug_log("VSCode module not available", vim.log.levels.WARN)
            return
          end
          
          -- Show mode in status bar
          local mode = vim.api.nvim_get_mode().mode:sub(1,1)
          local mode_text = "Mode: " .. ({
            n = "NORMAL",
            i = "INSERT",
            v = "VISUAL",
            V = "V-LINE",
            ["\22"] = "V-BLOCK",
            c = "COMMAND"
          })[mode] or "NORMAL"
          
          pcall(vscode.notify, mode_text)
        end,
      })
    end
    
    module_loader = fallback_loader
  end

  -- Define module system
  local module_system = {
    vscode = {
      "vsc-which-key",
      "vsc-commands",
      "vsc-keybindings",
      "vsc-jumpy"
    }
  }

  -- Collect plugin specs
  local function collect_plugin_specs()
    debug_log("Collecting plugin specs")
    local specs = module_loader.get_plugin_specs(module_system)
    return specs
  end

  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    debug_log("Failed to load lazy.nvim: " .. tostring(lazy), vim.log.levels.ERROR)
    return
  end

  debug_log("Setting up lazy.nvim with plugin specs")
  lazy.setup(collect_plugin_specs())
  
  debug_log("Setting up modules")
  module_loader.setup_modules(module_system)
end

-- Safeguard for ephemeral buffers
local function is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted")
end

-- Main initialization function
local function init()
  debug_log("Starting initialization sequence")
  
  -- If running under VSCode, override notifications to use VSCode UI
  if vim.g.vscode then
    local ok, vscode_mod = pcall(require, "vscode")
    if ok and vscode_mod.notify then
      debug_log("Setting up VSCode notification handler")
      vim.notify = vscode_mod.notify
    else
      debug_log("VSCode module not available yet, will try setting it up later", vim.log.levels.WARN)
      
      -- Set up a deferred loading mechanism for the vscode module
      vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        callback = function()
          debug_log("UIEnter event triggered, trying to load VSCode module again")
          local vscode_ok, vscode = pcall(require, "vscode")
          if vscode_ok then
            debug_log("Successfully loaded VSCode module on UIEnter")
            vim.notify = vscode.notify
            
            -- Initialize VSCode features on a delay to ensure UI is ready
            vim.defer_fn(function()
              debug_log("Setting up VSCode features with delay")
              pcall(setup_vscode_integration)
              
              -- Try to set up basic keybindings manually if needed
              if not vim.g.vscode_features_initialized then
                debug_log("Setting up basic VSCode keybindings")
                
                -- Set up basic mode indicator
                local mode_data = {
                  n = { text = 'NORMAL', color = '#7aa2f7' },
                  i = { text = 'INSERT', color = '#9ece6a' },
                  v = { text = 'VISUAL', color = '#bb9af7' },
                  c = { text = 'COMMAND', color = '#7dcfff' },
                }
                
                -- Update mode display in status bar
                local function update_mode_display()
                  local full_mode = vim.api.nvim_get_mode().mode
                  local mode_key = full_mode:sub(1,1)
                  local data = mode_data[mode_key] or mode_data.n
                  vscode.notify("Mode: " .. data.text)
                end
                
                vim.api.nvim_create_autocmd("ModeChanged", {
                  pattern = "*",
                  callback = update_mode_display
                })
                
                update_mode_display()
                vim.g.vscode_features_initialized = true
              end
            end, 200)
          else
            debug_log("VSCode module still not available after UIEnter", vim.log.levels.ERROR)
          end
        end
      })
    end
  end
  
  -- Basic initialization - works even if subsequent steps fail
  debug_log("Setting up lazy.nvim")
  setup_lazy()
  
  debug_log("Setting up leader key")
  setup_leader()
  
  debug_log("Setting up common settings")
  setup_common_settings()
  
  debug_log("Setting up VSCode integration")
  setup_vscode_integration()
  
  -- Try to load plugins (may fail if modules aren't available)
  debug_log("Attempting to set up plugins")
  pcall(setup_plugins)
  
  debug_log("Initialization complete")
end

-- Override Neovim's buffer-related commands to check for valid buffers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if not is_valid_buffer(bufnr) then
      vim.notify("Ignoring ephemeral buffer: " .. tostring(bufnr), vim.log.levels.WARN)
      return
    end
  end,
})

-- Run initialization
init()