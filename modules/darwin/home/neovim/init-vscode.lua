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
      name = " Find",
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
      name = " Jumpy",
      action = "extension.jumpy-word",
      subcommands = {
        w = { name = "Jumpy Word Mode", action = "extension.jumpy-word" },
        l = { name = "Jumpy Line Mode", action = "extension.jumpy-line" },
      }
    },
    g = {
      name = " Git",
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
      name = " Code",
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
      name = " Window",
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
      name = " Toggle",
      action = "workbench.action.terminal.toggleTerminal",
      subcommands = {
        e = { name = "Explorer", action = "workbench.view.explorer" },
        t = { name = "Terminal", action = "workbench.action.terminal.toggleTerminal" },
        p = { name = "Problems", action = "workbench.actions.view.problems" },
        m = { name = "Command Palette", action = "workbench.action.showCommands" },
      }
    },
  }
  
  -- Setup direct keybindings for all commands
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
  
  -- Global which-key state
  local which_key_state = {
    active_group = nil,
    quickpick = nil
  }
  
  -- QuickPick interface for which-key-like functionality
  local function show_which_key_menu()
    log("Showing which-key menu")
    
    -- Hide any existing quickpick
    if which_key_state.quickpick then
      hide_which_key_menu()
    end
    
    -- Prepare items for the quickpick
    local items = {}
    for prefix, group in pairs(keybinding_groups) do
      table.insert(items, {
        label = prefix .. ": " .. group.name,
        description = "Press key to execute or see submenu",
        prefix = prefix,
        -- Additional fields for reference
        group = group,
        action = group.action
      })
    end
    
    -- Create and configure quickpick
    local js_code = [[
      const quickPick = vscode.window.createQuickPick();
      quickPick.items = args.items.map(item => ({
        label: item.label,
        description: item.description,
        prefix: item.prefix,
        action: item.action,
        alwaysShow: true
      }));
      
      quickPick.title = "Which Key Menu";
      quickPick.placeholder = "Type a key to show submenu or select an item";
      
      // Create buttons for each group
      const buttons = args.items.map(item => ({
        iconPath: new vscode.ThemeIcon('key'),
        tooltip: 'Execute ' + item.label,
        item: item
      }));
      
      quickPick.buttons = buttons;
      
      // Handle button clicks (direct execution)
      quickPick.onDidTriggerButton(button => {
        if (button.item && button.item.action) {
          // Execute the command
          vscode.commands.executeCommand(button.item.action);
          quickPick.hide();
        }
      });
      
      // Handle selection changes
      quickPick.onDidChangeSelection(selection => {
        if (selection.length > 0) {
          const selected = selection[0];
          if (selected.prefix) {
            // When an item is selected, show its subcommands
            vscode.commands.executeCommand('vscode-neovim.send', '<Esc>');
            vscode.commands.executeCommand('vscode-neovim.send', '<Space>' + selected.prefix);
            quickPick.hide();
          }
        }
      });
      
      // Handle direct key presses
      quickPick.onDidChangeValue(value => {
        // If single letter is typed, it's likely a shortcut
        if (value.length === 1) {
          // Look for matching shortcut by key
          const matchingItem = args.items.find(item => 
            item.prefix && item.prefix.toLowerCase() === value.toLowerCase());
            
          if (matchingItem) {
            // Send key sequence to open submenu
            vscode.commands.executeCommand('vscode-neovim.send', '<Esc>');
            vscode.commands.executeCommand('vscode-neovim.send', '<Space>' + matchingItem.prefix);
            quickPick.hide();
          }
        }
      });
      
      // Handle hiding
      quickPick.onDidHide(() => {
        vscode.commands.executeCommand('vscode-neovim.lua', 'require("which-key-state").active_group = nil');
        quickPick.dispose();
      });
      
      // Store in global for later access
      if (globalThis.whichKeyQuickPick) {
        globalThis.whichKeyQuickPick.dispose();
      }
      globalThis.whichKeyQuickPick = quickPick;
      
      // Show the quickpick
      quickPick.show();
    ]]
    
    -- Execute the JS code in VSCode
    local eval_ok, eval_err = pcall(vscode.eval, js_code, {
      timeout = 3000,
      args = {
        items = items
      }
    })
    
    if not eval_ok then
      log("ERROR: Failed to show which-key menu: " .. tostring(eval_err))
    else
      log("SUCCESS: Showed which-key menu")
    end
  end
  
  -- Show subcommands for a specific group
  local function show_which_key_submenu(prefix, group)
    log("Showing submenu for: " .. prefix)
    which_key_state.active_group = prefix
    
    -- Hide any existing quickpick
    if which_key_state.quickpick then
      hide_which_key_menu()
    end
    
    -- Prepare submenu items
    local items = {}
    for key, subcmd in pairs(group.subcommands or {}) do
      table.insert(items, {
        label = key .. ": " .. subcmd.name,
        description = "Press key to execute",
        key = key,
        action = subcmd.action
      })
    end
    
    -- Create buttons for direct execution
    local buttons = {}
    for _, item in ipairs(items) do
      table.insert(buttons, {
        iconPath = "key",
        tooltip = "Execute " .. item.label,
        key = item.key,
        action = item.action
      })
    end
    
    -- Create and configure quickpick for submenu
    local js_code = [[
      const quickPick = vscode.window.createQuickPick();
      quickPick.items = args.items.map(item => ({
        label: item.label,
        description: item.description,
        key: item.key,
        action: item.action,
        alwaysShow: true
      }));
      
      quickPick.title = args.title;
      quickPick.placeholder = "Type a key to execute command";
      
      // Create buttons for each command
      const buttons = args.items.map(item => ({
        iconPath: new vscode.ThemeIcon('play'),
        tooltip: 'Execute ' + item.label,
        item: item
      }));
      
      quickPick.buttons = buttons;
      
      // Handle button clicks (direct execution)
      quickPick.onDidTriggerButton(button => {
        if (button.item && button.item.action) {
          // Execute the command
          vscode.commands.executeCommand(button.item.action);
          quickPick.hide();
        }
      });
      
      // Handle selection changes (double click or Enter)
      quickPick.onDidChangeSelection(selection => {
        if (selection.length > 0) {
          const selected = selection[0];
          if (selected.action) {
            // Execute the command
            vscode.commands.executeCommand(selected.action);
            quickPick.hide();
          }
        }
      });
      
      // Handle direct key presses
      quickPick.onDidChangeValue(value => {
        // If single letter is typed, it's likely a shortcut
        if (value.length === 1) {
          // Look for matching shortcut by key
          const matchingItem = args.items.find(item => 
            item.key && item.key.toLowerCase() === value.toLowerCase());
            
          if (matchingItem) {
            // Execute the matching command
            vscode.commands.executeCommand(matchingItem.action);
            quickPick.hide();
          }
        }
      });
      
      // Handle accepting via Enter
      quickPick.onDidAccept(() => {
        const selection = quickPick.selectedItems;
        if (selection.length > 0) {
          const selected = selection[0];
          if (selected.action) {
            // Execute the command
            vscode.commands.executeCommand(selected.action);
            quickPick.hide();
          }
        }
      });
      
      // Handle hiding
      quickPick.onDidHide(() => {
        vscode.commands.executeCommand('vscode-neovim.lua', 'require("which-key-state").active_group = nil');
        quickPick.dispose();
      });
      
      // Store in global for later access
      if (globalThis.whichKeyQuickPick) {
        globalThis.whichKeyQuickPick.dispose();
      }
      globalThis.whichKeyQuickPick = quickPick;
      
      // Show the quickpick
      quickPick.show();
    ]]
    
    -- Execute the JS code in VSCode
    local eval_ok, eval_err = pcall(vscode.eval, js_code, {
      timeout = 3000,
      args = {
        items = items,
        title = "Submenu: " .. group.name
      }
    })
    
    if not eval_ok then
      log("ERROR: Failed to show submenu: " .. tostring(eval_err))
    else
      log("SUCCESS: Showed submenu for " .. prefix)
    end
  end
  
  -- Hide the which-key menu
  local function hide_which_key_menu()
    log("Hiding which-key menu")
    
    local js_code = [[
      if (globalThis.whichKeyQuickPick) {
        globalThis.whichKeyQuickPick.hide();
        globalThis.whichKeyQuickPick.dispose();
        globalThis.whichKeyQuickPick = undefined;
      }
    ]]
    
    pcall(vscode.eval, js_code, { timeout = 1000 })
    which_key_state.active_group = nil
  end
  
  -- Store the which-key state for access from JavaScript
  _G["which-key-state"] = which_key_state
  
  -- Setup the which-key menu activation with leader key
  vim.keymap.set("n", "<leader>", function()
    log("Leader key pressed - showing which-key menu")
    
    -- If a group is already active, just execute the action
    if which_key_state.active_group then
      local prefix = which_key_state.active_group
      if keybinding_groups[prefix] then
        local action = keybinding_groups[prefix].action
        log("Executing action for active group: " .. action)
        pcall(vscode.action, action)
      end
      hide_which_key_menu()
      return true
    end
    
    -- Show the which-key menu
    show_which_key_menu()
    
    -- Return true for the leader key to be available for the next key
    return true
  end, { noremap = true, silent = true, expr = true })
  
  -- Create a mapping for each key to catch direct key presses after leader
  for prefix, group in pairs(keybinding_groups) do
    -- Set up a listener for <leader><key> to directly show the submenu
    vim.keymap.set("n", "<leader>" .. prefix, function()
      log("Leader and group key pressed directly: " .. prefix)
      show_which_key_submenu(prefix, group)
      return true
    end, { noremap = true, silent = true, expr = true })
  end
  
  -- Create direct key mappings for submenu entries
  for prefix, group in pairs(keybinding_groups) do
    if group.subcommands then
      for key, subcmd in pairs(group.subcommands) do
        local full_key = "<leader>" .. prefix .. key
        log("Setting up direct subcommand keybinding: " .. full_key .. " -> " .. subcmd.action)
        
        vim.keymap.set("n", full_key, function()
          log("Executing direct subcommand: " .. subcmd.action)
          pcall(vscode.action, subcmd.action)
          return true
        end, { noremap = true, silent = true, expr = true, desc = subcmd.name })
      end
    end
  end
  
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
      
      // Make the status bar clickable to toggle mode
      statusBar.command = {
        title: 'Toggle Neovim Mode',
        command: 'vscode-neovim.send',
        arguments: [args.mode === 'n' ? 'i' : '<Esc>']
      };
      
      statusBar.tooltip = "Click to toggle between Normal and Insert mode";
      statusBar.show();
      globalThis.modeStatusBar = statusBar;
    ]]
    
    local eval_ok, eval_err = pcall(vscode.eval, js_code, {
      timeout = 2000,
      args = {
        text = mode_text,
        color = mode_data.color,
        mode = mode_key
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
    VSCode-Neovim is now configured with:
    
    1. Interactive leader menu with submenus - press <leader> to access
    2. Jumpy integration for navigation - use <leader>h for jumpy commands
    3. All keybindings are still directly accessible (<leader>xy)
    
    Make sure you have the Jumpy extension installed from the VS Code marketplace.
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

-- Run initialization
init()

-- Final instructions to help user
log("\nVSCode Neovim initialization completed. If you don't see the which-key popup or mode display, please:")
log("1. Check the log file at: " .. log_path)
log("2. Ensure the vscode-neovim extension is properly installed")
log("3. Ensure Jumpy extension is installed for the jump functionality")
log("4. Try restarting VSCode")
