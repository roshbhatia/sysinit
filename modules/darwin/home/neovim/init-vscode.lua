-- Mark this is a VSCode instance
vim.g.vscode = true

-- Create a log file for debugging
local log_path = vim.fn.stdpath("data") .. "/vscode-debug.log"
local function log(message)
  local file = io.open(log_path, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
    file:close()
  end
  vim.notify(message)
end

log("==================== VSCode Neovim Init ====================")
log("Beginning VSCode Neovim initialization")

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
  
  log("Lazy.nvim and lua directories added to runtime path")
end

-- Basic leader setup
local function setup_leader()
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  -- Prevent space from moving cursor in normal/visual mode
  vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })
  log("Leader key configured")
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
  
  log("Common settings configured")
end

-- VSCode integration specific settings
local function setup_vscode_integration()
  if not vim.g.vscode then return end
  -- Suppress VimEnter autocommands to avoid premature remote plugin bootstrap errors
  vim.cmd("set eventignore+=VimEnter")
  log("VSCode integration settings applied")
end

-- Direct VSCode features (with no dependencies)
local function setup_direct_vscode_features()
  log("Setting up direct VSCode features")
  
  -- First, check if we have VSCode module
  local vscode_ok, vscode = pcall(require, "vscode")
  if not vscode_ok then
    log("ERROR: vscode module not available: " .. tostring(vscode))
    
    -- Setup deferred loading
    vim.api.nvim_create_autocmd("UIEnter", {
      once = true,
      callback = function()
        log("UIEnter triggered, trying to load vscode module again")
        local retry_ok, retry_vscode = pcall(require, "vscode")
        if retry_ok then
          log("SUCCESS: vscode module available on UIEnter")
          setup_vscode_with_module(retry_vscode)
        else
          log("ERROR: vscode module still not available on UIEnter: " .. tostring(retry_vscode))
        end
      end
    })
    
    return
  end
  
  log("SUCCESS: vscode module available")
  setup_vscode_with_module(vscode)
end

-- Setup VSCode features when the module is available
function setup_vscode_with_module(vscode)
  log("Setting up VSCode features with vscode module")
  
  -- Override notifications to use VSCode UI
  vim.notify = vscode.notify
  
  -- Setup which-key style leader menu
  log("Setting up which-key style menu")
  
  -- Define the keybinding groups for which-key style display
  local keybinding_groups = {
    f = {
      name = "🔍 Find",
      action = "workbench.action.quickOpen", 
      subcommands = {
        f = { name = "Find Files", action = "search-preview.quickOpenWithPreview" },
        g = { name = "Find in Files", action = "workbench.action.findInFiles" },
        b = { name = "Find Buffers", action = "workbench.action.showAllEditors" },
        s = { name = "Find Symbols", action = "workbench.action.showAllSymbols" },
        r = { name = "Recent Files", action = "workbench.action.openRecent" },
      }
    },
    h = {
      name = "🦘 Jumpy",
      action = "extension.jumpy-word",
      subcommands = {
        w = { name = "Jumpy Word Mode", action = "extension.jumpy-word" },
        l = { name = "Jumpy Line Mode", action = "extension.jumpy-line" },
      }
    },
    g = {
      name = "🔄 Git",
      action = "workbench.view.scm",
      subcommands = {
        s = { name = "Stage Changes", action = "git.stage" },
        u = { name = "Unstage Changes", action = "git.unstage" },
        c = { name = "Commit", action = "git.commit" },
        p = { name = "Push", action = "git.push" },
        P = { name = "Pull", action = "git.pull" },
      }
    },
    c = {
      name = "💻 Code",
      action = "editor.action.quickFix",
      subcommands = {
        a = { name = "Quick Fix", action = "editor.action.quickFix" },
        r = { name = "Rename Symbol", action = "editor.action.rename" },
        f = { name = "Format Document", action = "editor.action.formatDocument" },
        d = { name = "Go to Definition", action = "editor.action.revealDefinition" },
        i = { name = "Go to Implementation", action = "editor.action.goToImplementation" },
      }
    },
    w = {
      name = "🪟 Window",
      action = "workbench.action.focusFirstEditorGroup",
      subcommands = {
        h = { name = "Focus Left", action = "workbench.action.focusLeftGroup" },
        j = { name = "Focus Down", action = "workbench.action.focusBelowGroup" },
        k = { name = "Focus Up", action = "workbench.action.focusAboveGroup" },
        l = { name = "Focus Right", action = "workbench.action.focusRightGroup" },
        ["="] = { name = "Equal Width", action = "workbench.action.evenEditorWidths" },
      }
    },
    t = {
      name = "🔧 Toggle",
      action = "workbench.action.terminal.toggleTerminal",
      subcommands = {
        e = { name = "Explorer", action = "workbench.view.explorer" },
        t = { name = "Terminal", action = "workbench.action.terminal.toggleTerminal" },
        p = { name = "Problems", action = "workbench.actions.view.problems" },
        m = { name = "Command Palette", action = "workbench.action.showCommands" },
      }
    },
  }
  
  -- Just setup the direct keybindings without any fancy overlay
  for prefix, group in pairs(keybinding_groups) do
    -- Lead action for the group
    local leader_prefix = "<leader>" .. prefix
    vim.keymap.set("n", leader_prefix, function()
      log("Executing group action: " .. group.action)
      local ok, err = pcall(vscode.action, group.action)
      if not ok then
        log("ERROR executing action: " .. tostring(err))
      end
    end, { noremap = true, silent = true, desc = group.name })
    
    -- Setup subcommands
    if group.subcommands then
      for key, subcmd in pairs(group.subcommands) do
        local full_key = leader_prefix .. key
        log("Setting up keybinding: " .. full_key .. " -> " .. subcmd.action)
        
        vim.keymap.set("n", full_key, function()
          log("Executing action: " .. subcmd.action)
          local ok, err = pcall(vscode.action, subcmd.action)
          if not ok then
            log("ERROR executing action: " .. tostring(err))
          end
        end, { noremap = true, silent = true, desc = subcmd.name })
      end
    end
  end
  
  -- Create a simple notification-based which-key helper
  -- This will at least show a message with available keys when leader is pressed
  vim.keymap.set("n", "<leader>", function()
    -- Show a simple notification with available commands
    local message = "Available commands:\n\n"
    for prefix, group in pairs(keybinding_groups) do
      message = message .. prefix .. ": " .. group.name .. "\n"
    end
    message = message .. "\nPress a key to continue..."
    
    vscode.notify(message, vim.log.levels.INFO)
    
    -- Return true to allow the leader key to be used in the next keybinding
    return true
  end, { noremap = true, silent = true, expr = true })
  
  -- Setup jumpy keybindings
  log("Setting up Jumpy extension mappings")
  
  vim.keymap.set("n", "<leader>hw", function()
    log("Executing Jumpy Word Mode")
    local ok, err = pcall(vscode.action, "extension.jumpy-word")
    if not ok then
      log("ERROR executing Jumpy Word Mode: " .. tostring(err))
    end
  end, { noremap = true, silent = true, desc = "Jumpy Word Mode" })
  
  vim.keymap.set("n", "<leader>hl", function()
    log("Executing Jumpy Line Mode")
    local ok, err = pcall(vscode.action, "extension.jumpy-line")
    if not ok then
      log("ERROR executing Jumpy Line Mode: " .. tostring(err))
    end
  end, { noremap = true, silent = true, desc = "Jumpy Line Mode" })
  
  -- Replace f/F with Jumpy for character navigation
  vim.keymap.set({"n", "v", "o"}, "f", function()
    log("Executing Jumpy Word Mode (f key)")
    local ok, err = pcall(vscode.action, "extension.jumpy-word")
    if not ok then
      log("ERROR executing Jumpy Word Mode: " .. tostring(err))
    end
  end, { noremap = true, silent = true, desc = "Jumpy Word Mode" })
  
  -- Setup basic window navigation
  log("Setting up window navigation keybindings")
  
  local opts = { noremap = true, silent = true }
  
  vim.keymap.set("n", "<C-h>", function() 
    log("Executing: Focus Left Group")
    pcall(vscode.action, "workbench.action.focusLeftGroup") 
  end, opts)
  
  vim.keymap.set("n", "<C-j>", function() 
    log("Executing: Focus Down Group")
    pcall(vscode.action, "workbench.action.focusBelowGroup") 
  end, opts)
  
  vim.keymap.set("n", "<C-k>", function() 
    log("Executing: Focus Up Group")
    pcall(vscode.action, "workbench.action.focusAboveGroup") 
  end, opts)
  
  vim.keymap.set("n", "<C-l>", function() 
    log("Executing: Focus Right Group")
    pcall(vscode.action, "workbench.action.focusRightGroup") 
  end, opts)
  
  -- Setup mode display in status bar
  log("Setting up mode display")
  
  local MODE_DISPLAY = {
    n = { text = 'NORMAL', color = '#7aa2f7' },
    i = { text = 'INSERT', color = '#9ece6a' },
    v = { text = 'VISUAL', color = '#bb9af7' },
    V = { text = 'V-LINE', color = '#bb9af7' },
    ['\22'] = { text = 'V-BLOCK', color = '#bb9af7' },
    R = { text = 'REPLACE', color = '#f7768e' },
    c = { text = 'COMMAND', color = '#7dcfff' },
    t = { text = 'TERMINAL', color = '#73daca' },
  }
  
  local last_mode = nil
  
  local function update_mode_display()
    local mode = vim.api.nvim_get_mode().mode
    local mode_key = mode:sub(1,1)
    if mode_key == last_mode then return end
    
    local mode_data = MODE_DISPLAY[mode_key] or MODE_DISPLAY.n
    local mode_text = "Mode: " .. mode_data.text
    
    log("Updating mode display: " .. mode_text)
    
    local js_code = [[
      if (globalThis.modeStatusBar) { globalThis.modeStatusBar.dispose(); }
      const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
      statusBar.text = args.text;
      statusBar.color = args.color;
      statusBar.show();
      globalThis.modeStatusBar = statusBar;
    ]]
    
    local eval_ok, eval_err = pcall(vscode.eval, js_code, {
      timeout = 2000,
      args = {
        text = mode_text,
        color = mode_data.color
      }
    })
    
    if not eval_ok then
      log("ERROR: Failed to update mode display: " .. tostring(eval_err))
    else
      log("SUCCESS: Updated mode display")
      last_mode = mode_key
    end
  end
  
  -- Update mode on mode changes
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*",
    callback = update_mode_display
  })
  
  -- Initial mode display
  update_mode_display()
  log("Mode display configured")
  
  -- Notify user about Jumpy
  vim.notify([[
    VSCode-Neovim is configured with:
    
    1. Direct keybindings for all commands (e.g., <leader>ff for Find Files)
    2. Jumpy integration using <leader>hw for word mode and <leader>hl for line mode
    3. Simple notification-based which-key menu when pressing <leader>
    
    Make sure you have the Jumpy extension installed from the VS Code marketplace:
    https://marketplace.visualstudio.com/items?itemName=wmaurer.vscode-jumpy
  ]], vim.log.levels.INFO)
  
  log("VSCode features setup complete")
end

-- Main initialization function
local function init()
  log("Starting initialization sequence")
  
  -- Basic initialization - works even if subsequent steps fail
  setup_lazy()
  setup_leader()
  setup_common_settings()
  setup_vscode_integration()
  
  -- Setup direct VSCode features
  if vim.g.vscode then
    setup_direct_vscode_features()
  end
  
  log("Initialization complete")
end

-- Run initialization
init()

-- Final instructions to help user
log("\nVSCode Neovim initialization completed. If you don't see the which-key popup or mode display, please:")
log("1. Check the log file at: " .. log_path)
log("2. Ensure the vscode-neovim extension is properly installed")
log("3. Ensure Jumpy extension is installed for the jump functionality")
log("4. Try restarting VSCode")
