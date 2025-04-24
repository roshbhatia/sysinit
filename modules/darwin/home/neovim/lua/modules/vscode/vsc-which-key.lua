local M = {}

-- Define keybinding groups for which-key style menu
M.keybindings = {
  h = {
    name = "🦘 Jumpy",
    bindings = {
      { key = "w", description = "Jumpy Word Mode", action = "extension.jumpy-word" },
      { key = "l", description = "Jumpy Line Mode", action = "extension.jumpy-line" },
    },
  },
  f = {
    name = "🔍 Find",
    bindings = {
      { key = "f", description = "Find Files",    action = "search-preview.quickOpenWithPreview" },
      { key = "g", description = "Find in Files", action = "workbench.action.findInFiles" },
      { key = "b", description = "Find Buffers",  action = "workbench.action.showAllEditors" },
      { key = "s", description = "Find Symbols",  action = "workbench.action.showAllSymbols" },
      { key = "r", description = "Recent Files",  action = "workbench.action.openRecent" },
    },
  },
  w = {
    name = "🪟 Window",
    bindings = {
      { key = "h", description = "Focus Left",   action = "workbench.action.focusLeftGroup" },
      { key = "j", description = "Focus Down",   action = "workbench.action.focusBelowGroup" },
      { key = "k", description = "Focus Up",     action = "workbench.action.focusAboveGroup" },
      { key = "l", description = "Focus Right",  action = "workbench.action.focusRightGroup" },
      { key = "=", description = "Equal Width",  action = "workbench.action.evenEditorWidths" },
      { key = "_", description = "Max Width",    action = "workbench.action.toggleEditorWidths" },
      { key = "w", description = "Close Editor", action = "workbench.action.closeActiveEditor" },
      { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" },
      { key = "H", description = "Move Left",    action = "workbench.action.moveEditorToLeftGroup" },
      { key = "J", description = "Move Down",    action = "workbench.action.moveEditorToBelowGroup" },
      { key = "K", description = "Move Up",      action = "workbench.action.moveEditorToAboveGroup" },
      { key = "L", description = "Move Right",   action = "workbench.action.moveEditorToRightGroup" },
    },
  },
  u = {
    name = "⚙️ UI",
    bindings = {
      { key = "a", description = "Activity Bar", action = "workbench.action.toggleActivityBarVisibility" },
      { key = "s", description = "Status Bar",   action = "workbench.action.toggleStatusbarVisibility" },
      { key = "t", description = "Tab Bar",      action = "workbench.action.toggleTabsVisibility" },
      { key = "b", description = "Side Bar",     action = "workbench.action.toggleSidebarVisibility" },
      { key = "z", description = "Zen Mode",     action = "workbench.action.toggleZenMode" },
      { key = "f", description = "Full Screen",  action = "workbench.action.toggleFullScreen" },
    },
  },
  b = {
    name = "📝 Buffer",
    bindings = {
      { key = "n", description = "Next Buffer",     action = "workbench.action.nextEditor" },
      { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
      { key = "d", description = "Close Buffer",    action = "workbench.action.closeActiveEditor" },
      { key = "o", description = "Close Others",    action = "workbench.action.closeOtherEditors" },
    },
  },
  g = {
    name = "🔄 Git",
    bindings = {
      { key = "s", description = "Stage Changes",           action = "git.stage" },
      { key = "S", description = "Stage All",              action = "git.stageAll" },
      { key = "u", description = "Unstage Changes",        action = "git.unstage" },
      { key = "U", description = "Unstage All",           action = "git.unstageAll" },
      { key = "c", description = "Commit",                 action = "git.commit" },
      { key = "C", description = "Commit All",             action = "git.commitAll" },
      { key = "p", description = "Push",                   action = "git.push" },
      { key = "P", description = "Pull",                   action = "git.pull" },
      { key = "d", description = "Open Change",            action = "git.openChange" },
      { key = "D", description = "Open All Changes",       action = "git.openAllChanges" },
      { key = "b", description = "Checkout Branch",        action = "git.checkout" },
      { key = "f", description = "Fetch",                  action = "git.fetch" },
      { key = "r", description = "Revert Change",          action = "git.revertChange" },
      { key = "v", description = "SCM View",               action = "workbench.view.scm" },
      { key = "m", description = "Generate Commit Message", action = "workbench.action.chat.open" },
      { key = "e", description = "Open File Explorer",     action = "workbench.view.explorer" },
      { key = "h", description = "Stage Selected Ranges",  action = "git.stageSelectedRanges" },
      { key = "j", description = "Next Change",           action = "workbench.action.editor.nextChange" },
      { key = "k", description = "Previous Change",       action = "workbench.action.editor.previousChange" },
      { key = "l", description = "Unstage Selected Ranges", action = "git.unstageSelectedRanges" },
    },
  },
  c = {
    name = "💻 Code",
    bindings = {
      { key = "a", description = "Quick Fix",            action = "editor.action.quickFix" },
      { key = "r", description = "Rename Symbol",        action = "editor.action.rename" },
      { key = "f", description = "Format Document",      action = "editor.action.formatDocument" },
      { key = "d", description = "Go to Definition",     action = "editor.action.revealDefinition" },
      { key = "i", description = "Go to Implementation", action = "editor.action.goToImplementation" },
      { key = "h", description = "Show Hover",           action = "editor.action.showHover" },
      { key = "c", description = "Toggle Comment",       action = "editor.action.commentLine" },
      { key = "s", description = "Go to Symbol",         action = "workbench.action.gotoSymbol" },
      { key = "R", description = "Find References",      action = "editor.action.goToReferences" },
    },
  },
  t = {
    name = "🔧 Toggle",
    bindings = {
      { key = "e", description = "Explorer",         action = "workbench.view.explorer" },
      { key = "t", description = "Terminal",         action = "workbench.action.terminal.toggleTerminal" },
      { key = "p", description = "Problems",         action = "workbench.actions.view.problems" },
      { key = "o", description = "Outline",          action = "outline.focus" },
      { key = "c", description = "Chat",             action = "workbench.action.chat.open" },
      { key = "b", description = "Return to Editor", action = "workbench.action.focusActiveEditorGroup" },
      { key = "m", description = "Command Palette",  action = "workbench.action.showCommands" },
    },
  },
  a = {
    name = "🤖 AI",
    bindings = {
      { key = "c", description = "Start Chat",      action = "workbench.action.chat.open" },
      { key = "i", description = "Inline Chat",     action = "inlineChat.start" },
      { key = "v", description = "View in Chat",    action = "inlineChat.viewInChat" },
      { key = "r", description = "Regenerate",      action = "inlineChat.regenerate" },
      { key = "a", description = "Accept Changes",  action = "inlineChat.acceptChanges" },
      { key = "g", description = "Generate Commit", action = "github.copilot.git.generateCommitMessage" },
    },
  },
  s = {
    name = "✂️ Stage/Split",
    bindings = {
      { key = "s", description = "Stage Hunk",       action = "git.diff.stageHunk" },
      { key = "S", description = "Stage Selection",  action = "git.diff.stageSelection" },
      { key = "u", description = "Unstage",          action = "git.unstage" },
      { key = "h", description = "Split Horizontal", action = "workbench.action.splitEditorDown" },
      { key = "v", description = "Split Vertical",   action = "workbench.action.splitEditorRight" },
    },
  },
}

-- JavaScript code templates for VSCode interaction
M.eval_strings = {
  mode_display = [[
    if (globalThis.modeStatusBar) { globalThis.modeStatusBar.dispose(); }
    const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBar.text = args.text;
    statusBar.color = args.color;
    statusBar.command = {
      command: 'vscode-neovim.lua',
      title: 'Toggle Neovim Mode',
      arguments: [
        args.mode === 'n'
          ? "vim.cmd('startinsert')"
          : "vim.cmd('stopinsert')"
      ]
    };
    statusBar.show();
    globalThis.modeStatusBar = statusBar;
  ]],
  quickpick_menu = [[
    if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
    const quickPick = vscode.window.createQuickPick();
    quickPick.items = args.items.map(item => ({
      label: item.isGroup ? `$(chevron-right) ${item.label}` : item.isGroupItem ? `  $(key) ${item.label}` : item.label,
      description: item.description,
      action: item.action,
      key: item.key,
      kind: item.kind
    }));
    quickPick.title = args.title;
    quickPick.placeholder = args.placeholder;
    quickPick.onDidAccept(() => {
      const selected = quickPick.selectedItems[0];
      if (selected && selected.action) {
        vscode.commands.executeCommand(selected.action);
      }
      quickPick.hide();
      quickPick.dispose();
    });
    quickPick.onDidHide(() => {
      quickPick.dispose();
    });
    globalThis.quickPick = quickPick;
    quickPick.show();
  ]],
  hide_quickpick = [[
    if (globalThis.quickPick) {
      globalThis.quickPick.hide();
      globalThis.quickPick.dispose();
      globalThis.quickPick = undefined;
    }
  ]],
}

M.plugins = {
  {
    "vscode-neovim/vscode-neovim",
    cond = function() return vim.g.vscode == true end,
    event = "UIEnter",
  }
}

function M.setup()
  if not vim.g.vscode then return end
  
  -- Define debug log function
  local function debug_log(msg, level)
    level = level or vim.log.levels.INFO
    -- Create a debug.log file in the Neovim data directory
    local log_path = vim.fn.stdpath("data") .. "/vscode-which-key-debug.log"
    local log_file = io.open(log_path, "a")
    if log_file then
      log_file:write(os.date("%Y-%m-%d %H:%M:%S ") .. msg .. "\n")
      log_file:close()
    end
    
    -- Also use Vim's notify system if available
    vim.notify(msg, level)
  end
  
  debug_log("Setting up vsc-which-key")
  
  -- Implementation of VSCode-compatible which-key menu system
  local which_key = {}
  
  -- Define mode display information
  local MODE_DISPLAY = {
    n = { text = 'NORMAL', color = '#7aa2f7' },
    i = { text = 'INSERT', color = '#9ece6a' },
    v = { text = 'VISUAL', color = '#bb9af7' },
    V = { text = 'V-LINE', color = '#bb9af7' },
    ['\22'] = { text = 'V-BLOCK', color = '#bb9af7' },
    R = { text = 'REPLACE', color = '#f7768e' },
    s = { text = 'SELECT', color = '#ff9e64' },
    S = { text = 'S-LINE', color = '#ff9e64' },
    ['\19'] = { text = 'S-BLOCK', color = '#ff9e64' },
    c = { text = 'COMMAND', color = '#7dcfff' },
    t = { text = 'TERMINAL', color = '#73daca' },
  }

  local mode_strings = {}
  local last_mode = nil
  
  for mode, data in pairs(MODE_DISPLAY) do
    mode_strings[mode] = string.format("Mode: %s", data.text)
  end
  
  -- Cached menu items
  local cache = {
    root_items = nil,
    group_items = {}
  }
  
  -- Safe utility for writing to files with error handling
  local function write_file(path, lines)
    local f, err = io.open(path, 'w')
    if not f then
      vim.notify('Error opening file: ' .. path .. ': ' .. err, vim.log.levels.ERROR)
      return
    end
    for _, line in ipairs(lines) do f:write(line .. '\n') end
    f:close()
  end

  -- Format menu items for a specific group
  local function format_menu_items(group)
    local items = {}
    for _, binding in ipairs(group.bindings) do
      table.insert(items, {
        label = binding.key,
        description = binding.description,
        action = binding.action,
        key = binding.key,
      })
    end
    return items
  end

  -- Format root menu items (all groups)
  local function format_root_menu_items()
    if cache.root_items then
      return cache.root_items
    end

    local items = {}
    local lastCategory = nil

    for key, group in pairs(M.keybindings) do
      if lastCategory then
        table.insert(items, {
          label = "──────────────",
          kind = -1,
        })
      end
      table.insert(items, {
        label = key,
        description = group.name,
        isGroup = true,
        key = key,
      })
      for _, binding in ipairs(group.bindings) do
        table.insert(items, {
          label = key .. binding.key,
          description = binding.description,
          action = binding.action,
          isGroupItem = true,
        })
      end
      lastCategory = key
    end

    cache.root_items = items
    return items
  end

  -- Show the which-key menu for a group or the root menu
  local function show_menu(group)
    debug_log("Attempting to show which-key menu")
    local vscode_ok, vscode = pcall(require, "vscode")
    if not vscode_ok then
      debug_log("VSCode module not available when showing menu", vim.log.levels.ERROR)
      return
    end
    
    local ok, items = pcall(function()
      return group and format_menu_items(group) or format_root_menu_items()
    end)
    
    if not ok then
      debug_log("Error formatting menu items: " .. tostring(items), vim.log.levels.ERROR)
      return
    end
    
    local title = group and group.name or "Which Key Menu"
    local placeholder = group
      and "Select an action or press <Esc> to cancel"
      or "Select a group or action (groups shown with ▸)"

    debug_log("Calling vscode.eval with quickpick_menu")
    local eval_ok, eval_err = pcall(vscode.eval, M.eval_strings.quickpick_menu, {
      timeout = 2000, -- Extend timeout
      args = {
        items = items,
        title = title,
        placeholder = placeholder,
      }
    })
    
    if not eval_ok then
      debug_log("Error showing which-key menu: " .. tostring(eval_err), vim.log.levels.ERROR)
    else
      debug_log("Successfully showed which-key menu")
    end
  end

  -- Hide the which-key menu
  local function hide_menu()
    local vscode_ok, vscode = pcall(require, "vscode")
    if not vscode_ok then return end
    
    pcall(vscode.eval, M.eval_strings.hide_quickpick, { timeout = 1000 })
  end

  -- Handle a specific key group
  local function handle_group(prefix, group)
    vim.keymap.set("n", prefix, function()
      show_menu(group)
    end, { noremap = true, silent = true })

    for _, binding in ipairs(group.bindings) do
      vim.keymap.set("n", prefix .. binding.key, function()
        hide_menu()
        local vscode_ok, vscode = pcall(require, "vscode")
        if vscode_ok then
          pcall(vscode.action, binding.action)
        end
      end, { noremap = true, silent = true })
    end
  end

  -- Update the mode display in the VSCode status bar
  local function update_mode_display()
    debug_log("Attempting to update mode display")
    local vscode_ok, vscode = pcall(require, "vscode")
    if not vscode_ok then
      debug_log("VSCode module not available when updating mode display", vim.log.levels.WARN)
      return
    end
    
    local full_mode = vim.api.nvim_get_mode().mode
    local mode_key = full_mode:sub(1,1)
    if mode_key == last_mode then 
      debug_log("Mode unchanged, skipping update")
      return 
    end
    local mode_data = MODE_DISPLAY[mode_key] or MODE_DISPLAY.n
    
    debug_log("Updating mode display to: " .. (mode_strings[mode_key] or mode_strings.n))
    local eval_ok, eval_err = pcall(vscode.eval, M.eval_strings.mode_display, {
      timeout = 2000, -- Extend timeout
      args = {
        text = mode_strings[mode_key] or mode_strings.n,
        color = mode_data.color,
        mode = mode_key
      }
    })
    
    if not eval_ok then
      debug_log("Error updating mode display: " .. tostring(eval_err), vim.log.levels.ERROR)
    else
      debug_log("Successfully updated mode display")
      last_mode = mode_key
    end
  end

  -- Main setup function
  which_key.setup = function()
    debug_log("Setting up which key keybindings")
    
    -- Show root menu when leader is pressed
    debug_log("Setting up leader key mapping")
    vim.keymap.set("n", "<leader>", function()
      debug_log("Leader key pressed, showing menu")
      show_menu()
    end, { noremap = true, silent = true, desc = "Show which-key menu" })

    -- Setup each group
    debug_log("Setting up group key mappings")
    for prefix, group in pairs(M.keybindings) do
      debug_log("Setting up mappings for group: " .. prefix)
      handle_group("<leader>" .. prefix, group)
    end

    -- Auto-hide menu on mode change or cursor move
    debug_log("Setting up auto-hide menu autocmds")
    vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved" }, {
      callback = hide_menu,
    })

    -- Update mode display in status bar
    debug_log("Setting up mode display autocmds")
    vim.api.nvim_create_autocmd("ModeChanged", {
      pattern = "*",
      callback = update_mode_display,
    })

    -- Update mode display when entering command mode
    debug_log("Setting up command mode autocmd")
    vim.api.nvim_create_autocmd("CmdlineEnter", {
      callback = function()
        debug_log("Command mode entered")
        local vscode_ok, vscode = pcall(require, "vscode")
        if not vscode_ok then
          debug_log("VSCode module not available in command mode", vim.log.levels.WARN)
          return
        end
        
        debug_log("Updating mode display to COMMAND")
        pcall(vscode.eval, M.eval_strings.mode_display, {
          timeout = 2000,
          args = {
            text = "COMMAND",
            color = MODE_DISPLAY.c.color,
            mode = 'c',
          }
        })
      end,
    })

    -- Initialize mode display
    debug_log("Initializing mode display")
    update_mode_display()
    
    -- Make sure the VSCode module is available
    debug_log("Setup completed, checking VSCode module availability")
    local vscode_ok, _ = pcall(require, "vscode")
    if not vscode_ok then
      debug_log("VSCode module still not available after setup - will retry on mode change", vim.log.levels.WARN)
      
      -- Create a timer to periodically check for VSCode module
      local timer_check = vim.loop.new_timer()
      if timer_check then
        timer_check:start(1000, 1000, vim.schedule_wrap(function()
          local check_ok, _ = pcall(require, "vscode")
          if check_ok then
            debug_log("VSCode module now available!")
            update_mode_display()
            timer_check:stop()
          else
            debug_log("VSCode module still not available...")
          end
        end))
      end
    end
  end
  
  -- Register which-key to the module
  M.which_key = which_key
end

return M