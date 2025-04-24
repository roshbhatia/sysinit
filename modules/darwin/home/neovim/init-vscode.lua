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
  
  local keybinding_groups = {
    { key = "f", name = "Find", action = "workbench.action.quickOpen" },
    { key = "g", name = "Git", action = "workbench.view.scm" },
    { key = "e", name = "Explorer", action = "workbench.view.explorer" },
    { key = "t", name = "Terminal", action = "workbench.action.terminal.toggleTerminal" },
    { key = "c", name = "Code", action = "editor.action.quickFix" },
    { key = "w", name = "Window", action = "workbench.action.focusFirstEditorGroup" },
  }
  
  -- Show root menu for leader key
  vim.keymap.set("n", "<leader>", function()
    log("Leader key pressed - showing menu")
    
    -- Create QuickPick menu in VSCode
    local js_code = [[
      if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
      const quickPick = vscode.window.createQuickPick();
      quickPick.items = args.items.map(item => ({
        label: item.key,
        description: item.name,
        action: item.action,
      }));
      quickPick.title = "VSCode Commands";
      quickPick.placeholder = "Select a command category";
      quickPick.onDidAccept(() => {
        const selected = quickPick.selectedItems[0];
        if (selected && selected.action) {
          vscode.commands.executeCommand(selected.action);
        }
        quickPick.hide();
      });
      quickPick.onDidHide(() => {
        quickPick.dispose();
        globalThis.quickPick = undefined;
      });
      globalThis.quickPick = quickPick;
      quickPick.show();
    ]]
    
    local eval_ok, eval_err = pcall(vscode.eval, js_code, {
      timeout = 3000,
      args = { items = keybinding_groups }
    })
    
    if not eval_ok then
      log("ERROR: Failed to show quickpick menu: " .. tostring(eval_err))
    else
      log("SUCCESS: Showed quickpick menu")
    end
  end, { noremap = true, silent = true })
  
  -- Setup direct keybindings for common actions
  log("Setting up common keybindings")
  
  local opts = { noremap = true, silent = true }
  
  -- Find files
  vim.keymap.set("n", "<leader>f", function()
    log("Executing: Find Files")
    pcall(vscode.action, "workbench.action.quickOpen")
  end, opts)
  
  -- Explorer
  vim.keymap.set("n", "<leader>e", function()
    log("Executing: Explorer")
    pcall(vscode.action, "workbench.view.explorer")
  end, opts)
  
  -- Terminal
  vim.keymap.set("n", "<leader>t", function()
    log("Executing: Terminal")
    pcall(vscode.action, "workbench.action.terminal.toggleTerminal")
  end, opts)
  
  -- Window navigation
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

-- Notify when entering buffers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    log("Entered buffer: " .. bufnr .. " - " .. (bufname ~= "" and bufname or "[No Name]"))
  end
})

-- Add a fallback mode display
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    local mode = vim.api.nvim_get_mode().mode
    local mode_text = "Mode: " .. ({
      n = "NORMAL",
      i = "INSERT",
      v = "VISUAL",
      V = "V-LINE",
      ["\22"] = "V-BLOCK",
      c = "COMMAND",
      t = "TERMINAL",
    })[mode:sub(1,1)] or "NORMAL"
    
    log("Mode changed: " .. mode_text .. " [fallback display]")
  end
})

-- Check VSCode module periodically
vim.defer_fn(function()
  local vscode_ok, vscode = pcall(require, "vscode")
  log("Checking VSCode module (delayed): " .. (vscode_ok and "AVAILABLE" or "NOT AVAILABLE"))
  
  if vscode_ok then
    log("VSCode module methods:")
    for k, v in pairs(vscode) do
      log("  - " .. k .. " (" .. type(v) .. ")")
    end
  end
end, 2000)

-- Run initialization
init()

-- Final instructions to help user
log("\nVSCode Neovim initialization completed. If you don't see the which-key popup or mode display, please:")
log("1. Check the log file at: " .. log_path)
log("2. Ensure the vscode-neovim extension is properly installed")
log("3. Try restarting VSCode with a simple init file like this one")
