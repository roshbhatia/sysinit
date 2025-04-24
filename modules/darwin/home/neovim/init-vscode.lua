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
  
  -- State for which-key system
  local which_key_state = {
    active = false,
    timeout_timer = nil,
    current_prefix = "",
    last_pressed_time = 0,
  }
  
  -- Handle each individual keybinding
  for prefix, group in pairs(keybinding_groups) do
    if group.subcommands then
      local leader_prefix = "<leader>" .. prefix
      
      -- Setup the group prefix key
      vim.keymap.set("n", leader_prefix, function()
        -- If pressed as part of sequence, execute directly
        if which_key_state.active and which_key_state.current_prefix == "<leader>" then
          log("Executing group action directly: " .. group.action)
          pcall(vscode.action, group.action)
          which_key_state.active = false
          return
        end
        
        -- Otherwise show subcommands
        show_which_key_submenu(vscode, prefix, group)
      end, { noremap = true, silent = true, desc = group.name })
      
      -- Setup each subcommand
      for key, subcmd in pairs(group.subcommands) do
        local full_key = leader_prefix .. key
        log("Setting up keybinding: " .. full_key .. " -> " .. subcmd.action)
        
        vim.keymap.set("n", full_key, function()
          log("Executing action: " .. subcmd.action)
          local ok, err = pcall(vscode.action, subcmd.action)
          if not ok then
            log("ERROR executing action: " .. tostring(err))
          end
          which_key_state.active = false
        end, { noremap = true, silent = true, desc = subcmd.name })
      end
    end
  end
  
  -- Function to create a which-key style display in VSCode
  function show_which_key_menu(vscode)
    log("Showing which-key root menu")
    
    -- Reset state
    which_key_state.active = true
    which_key_state.current_prefix = "<leader>"
    which_key_state.last_pressed_time = vim.loop.now()
    
    -- Create HTML for which-key display
    local html = [[
      <div style="
        background: rgba(30, 30, 30, 0.95);
        color: white;
        position: fixed;
        bottom: 20px;
        left: 50%;
        transform: translateX(-50%);
        padding: 10px 20px;
        border-radius: 5px;
        font-family: 'Courier New', monospace;
        font-size: 14px;
        box-shadow: 0 0 10px rgba(0,0,0,0.5);
        z-index: 9999;
        width: auto;
        max-width: 80%;
        display: flex;
        flex-direction: column;
      ">
        <div style="margin-bottom: 10px; font-weight: bold; text-align: center;">
          Key Bindings (press key to continue)
        </div>
        <div style="display: grid; grid-template-columns: repeat(6, auto); gap: 10px;">
    ]]
    
    -- Add each key group
    for prefix, group in pairs(keybinding_groups) do
      local color = "#8aadf4"
      html = html .. string.format([[
        <div style="text-align: center; padding: 5px; border: 1px solid %s; border-radius: 3px;">
          <span style="font-weight: bold; color: %s;">%s</span>
          <div>%s</div>
        </div>
      ]], color, color, prefix, group.name)
    end
    
    html = html .. [[
        </div>
      </div>
    ]]
    
    -- Show the menu using VSCode webview
    local js_code = string.format([[
      // Remove any existing overlay
      if (globalThis.whichKeyOverlay) {
        document.body.removeChild(globalThis.whichKeyOverlay);
        globalThis.whichKeyOverlay = undefined;
      }
      
      // Create new overlay
      const overlay = document.createElement('div');
      overlay.id = 'which-key-overlay';
      overlay.innerHTML = %q;
      document.body.appendChild(overlay);
      globalThis.whichKeyOverlay = overlay;
      
      // Auto-hide after timeout
      if (globalThis.whichKeyTimer) {
        clearTimeout(globalThis.whichKeyTimer);
      }
      
      globalThis.whichKeyTimer = setTimeout(() => {
        if (globalThis.whichKeyOverlay) {
          document.body.removeChild(globalThis.whichKeyOverlay);
          globalThis.whichKeyOverlay = undefined;
        }
      }, 3000);
    ]], html)
    
    local eval_ok, eval_err = pcall(vscode.eval, js_code, { timeout = 3000 })
    if not eval_ok then
      log("ERROR: Failed to show which-key menu: " .. tostring(eval_err))
    else
      log("SUCCESS: Showed which-key menu")
    end
    
    -- Set timer to auto-hide menu
    if which_key_state.timeout_timer then
      which_key_state.timeout_timer:stop()
    end
    
    which_key_state.timeout_timer = vim.defer_fn(function()
      hide_which_key_menu(vscode)
    end, 3000)
  end
  
  -- Function to show submenu for a group
  function show_which_key_submenu(vscode, prefix, group)
    log("Showing which-key submenu for: " .. prefix)
    
    -- Update state
    which_key_state.active = true
    which_key_state.current_prefix = "<leader>" .. prefix
    which_key_state.last_pressed_time = vim.loop.now()
    
    -- Create HTML for submenu
    local html = [[
      <div style="
        background: rgba(30, 30, 30, 0.95);
        color: white;
        position: fixed;
        bottom: 20px;
        left: 50%;
        transform: translateX(-50%);
        padding: 10px 20px;
        border-radius: 5px;
        font-family: 'Courier New', monospace;
        font-size: 14px;
        box-shadow: 0 0 10px rgba(0,0,0,0.5);
        z-index: 9999;
        width: auto;
        max-width: 80%;
        display: flex;
        flex-direction: column;
      ">
        <div style="margin-bottom: 10px; font-weight: bold; text-align: center;">
    ]] .. group.name .. [[ Commands (press key to execute)
        </div>
        <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 10px;">
    ]]
    
    -- Add each subcommand
    for key, subcmd in pairs(group.subcommands) do
      local color = "#a6da95"
      html = html .. string.format([[
        <div style="text-align: center; padding: 5px; border: 1px solid %s; border-radius: 3px;">
          <span style="font-weight: bold; color: %s;">%s</span>
          <div>%s</div>
        </div>
      ]], color, color, key, subcmd.name)
    end
    
    html = html .. [[
        </div>
      </div>
    ]]
    
    -- Show the submenu
    local js_code = string.format([[
      // Remove any existing overlay
      if (globalThis.whichKeyOverlay) {
        document.body.removeChild(globalThis.whichKeyOverlay);
        globalThis.whichKeyOverlay = undefined;
      }
      
      // Create new overlay
      const overlay = document.createElement('div');
      overlay.id = 'which-key-overlay';
      overlay.innerHTML = %q;
      document.body.appendChild(overlay);
      globalThis.whichKeyOverlay = overlay;
      
      // Auto-hide after timeout
      if (globalThis.whichKeyTimer) {
        clearTimeout(globalThis.whichKeyTimer);
      }
      
      globalThis.whichKeyTimer = setTimeout(() => {
        if (globalThis.whichKeyOverlay) {
          document.body.removeChild(globalThis.whichKeyOverlay);
          globalThis.whichKeyOverlay = undefined;
        }
      }, 3000);
    ]], html)
    
    local eval_ok, eval_err = pcall(vscode.eval, js_code, { timeout = 3000 })
    if not eval_ok then
      log("ERROR: Failed to show which-key submenu: " .. tostring(eval_err))
    else
      log("SUCCESS: Showed which-key submenu for " .. prefix)
    end
    
    -- Set timer to auto-hide menu
    if which_key_state.timeout_timer then
      which_key_state.timeout_timer:stop()
    end
    
    which_key_state.timeout_timer = vim.defer_fn(function()
      hide_which_key_menu(vscode)
    end, 3000)
  end
  
  -- Function to hide the which-key menu
  function hide_which_key_menu(vscode)
    log("Hiding which-key menu")
    
    which_key_state.active = false
    which_key_state.current_prefix = ""
    
    local js_code = [[
      if (globalThis.whichKeyOverlay) {
        document.body.removeChild(globalThis.whichKeyOverlay);
        globalThis.whichKeyOverlay = undefined;
      }
      
      if (globalThis.whichKeyTimer) {
        clearTimeout(globalThis.whichKeyTimer);
        globalThis.whichKeyTimer = undefined;
      }
    ]]
    
    pcall(vscode.eval, js_code, { timeout = 1000 })
  end
  
  -- Show which-key menu on leader key
  vim.keymap.set("n", "<leader>", function()
    log("Leader key pressed - showing menu")
    show_which_key_menu(vscode)
  end, { noremap = true, silent = true })
  
  -- Hide which-key menu on Escape
  vim.keymap.set("n", "<Esc>", function()
    if which_key_state.active then
      hide_which_key_menu(vscode)
      return false -- prevent default action
    end
  end, { noremap = true, silent = true, expr = true })
  
  -- Setup jumpy keybindings
  log("Setting up Jumpy extension mappings")
  
  vim.keymap.set("n", "<leader>hw", function()
    log("Executing Jumpy Word Mode")
    local ok, err = pcall(vscode.action, "extension.jumpy-word")
    if not ok then
      log("ERROR executing Jumpy Word Mode: " .. tostring(err))
    end
    which_key_state.active = false
  end, { noremap = true, silent = true, desc = "Jumpy Word Mode" })
  
  vim.keymap.set("n", "<leader>hl", function()
    log("Executing Jumpy Line Mode")
    local ok, err = pcall(vscode.action, "extension.jumpy-line")
    if not ok then
      log("ERROR executing Jumpy Line Mode: " .. tostring(err))
    end
    which_key_state.active = false
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
    VSCode-Neovim is configured to use Jumpy extension.
    Make sure you have it installed from the VS Code marketplace:
    https://marketplace.visualstudio.com/items?itemName=wmaurer.vscode-jumpy
    
    Use <leader>h for Jumpy commands.
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

-- Notify when entering buffers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    log("Entered buffer: " .. bufnr .. " - " .. (bufname ~= "" and bufname or "[No Name]"))
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
log("3. Ensure Jumpy extension is installed for the jump functionality")
log("4. Try restarting VSCode")
