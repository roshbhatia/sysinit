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

-- Setup VSCode-specific keybindings and features
local function setup_vscode_features()
  if not vim.g.vscode then return end

  local vscode_ok, vscode = pcall(require, "vscode")
  if not vscode_ok then
    vim.notify("Failed to load vscode module: " .. tostring(vscode), vim.log.levels.ERROR)
    return
  end

  -- =============================================
  -- VSCode Command Mapping
  -- =============================================
  local cmd_map = {
    w      = "workbench.action.files.save",
    wa     = "workbench.action.files.saveAll",
    q      = "workbench.action.closeActiveEditor",
    qa     = "workbench.action.quit",
    enew   = "workbench.action.files.newUntitledFile",
    bdelete= "workbench.action.closeActiveEditor",
    bn     = "workbench.action.nextEditor",
    bp     = "workbench.action.previousEditor",
    split  = "workbench.action.splitEditorDown",
    vsplit = "workbench.action.splitEditorRight",
  }

  -- Map Vim commands to VSCode actions
  local function map_cmd(mode, lhs, cmd, opts)
    opts = opts or { noremap = true, silent = true }
    local action = cmd_map[cmd]
    if action then
      vim.keymap.set(mode, lhs, function() vscode.action(action) end, opts)
    else
      vim.keymap.set(mode, lhs, '<cmd>' .. cmd .. '<cr>', opts)
    end
  end

  -- =============================================
  -- Which Key Menu Setup
  -- =============================================
  -- Define keybinding groups for which-key style menu
  local keybindings = {
    f = {
      name = "󰀶 Find",
      bindings = {
        { key = "f", description = "Find Files",    action = "search-preview.quickOpenWithPreview" },
        { key = "g", description = "Find in Files", action = "workbench.action.findInFiles" },
        { key = "b", description = "Find Buffers",  action = "workbench.action.showAllEditors" },
        { key = "s", description = "Find Symbols",  action = "workbench.action.showAllSymbols" },
        { key = "r", description = "Recent Files",  action = "workbench.action.openRecent" },
      },
    },
    w = {
      name = "󱂬 Window",
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
      name = " UI",
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
      name = " Buffer",
      bindings = {
        { key = "n", description = "Next Buffer",     action = "workbench.action.nextEditor" },
        { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
        { key = "d", description = "Close Buffer",    action = "workbench.action.closeActiveEditor" },
        { key = "o", description = "Close Others",    action = "workbench.action.closeOtherEditors" },
      },
    },
    g = {
      name = " Git",
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
        -- Stage/unstage in file explorer
        { key = "h", description = "Stage Selected Ranges",  action = "git.stageSelectedRanges" },
        { key = "j", description = "Next Change",           action = "workbench.action.editor.nextChange" },
        { key = "k", description = "Previous Change",       action = "workbench.action.editor.previousChange" },
        { key = "l", description = "Unstage Selected Ranges", action = "git.unstageSelectedRanges" },
      },
    },
    c = {
      name = "󰘧 Code",
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
      name = "󰨚 Toggle",
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
      name = "󱚟 AI",
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
      name = "󰓩 Stage/Split",
      bindings = {
        { key = "s", description = "Stage Hunk",       action = "git.diff.stageHunk" },
        { key = "S", description = "Stage Selection",  action = "git.diff.stageSelection" },
        { key = "u", description = "Unstage",          action = "git.unstage" },
        { key = "h", description = "Split Horizontal", action = "workbench.action.splitEditorDown" },
        { key = "v", description = "Split Vertical",   action = "workbench.action.splitEditorRight" },
      },
    },
  }

  -- =============================================
  -- Which Key Implementation
  -- =============================================
  -- Implements a VSCode-compatible which-key menu system
  local which_key = (function()
    local cache = {
      root_items = nil,
      group_items = {}
    }
    
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

    local function write_prompt(title, placeholder, items)
      local lines = {
        '# Which Key Prompt', '',
        '**Title**: ' .. title, '',
        '**Placeholder**: ' .. placeholder, '',
        'Items:', ''
      }
      for _, item in ipairs(items) do
        if item.kind == -1 then
          table.insert(lines, '- --- separator ---')
        else
          table.insert(lines, string.format(
            '- `%s`: %s (action: %s)',
            item.label, item.description or '', item.action or ''
          ))
        end
      end
      -- Use safe_prompt_file instead of direct reference
      local safe_prompt_file = vim.fn.tempname() .. "_vscode_prompt.md"
      write_file(safe_prompt_file, lines)
    end

    -- JavaScript code templates for VSCode interaction
    local EVAL_STRINGS = {
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
        const vscode = require('vscode');
        if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
        
        const quickPick = vscode.window.createQuickPick();
        quickPick.items = args.items.map(item => ({
          label: item.isGroup ? `$(chevron-right) ${item.label}` : item.isGroupItem ? `  $(key) ${item.label}` : item.label,
          description: item.description,
          action: item.action,
          key: item.key,
          kind: item.kind,
          isGroup: item.isGroup
        }));
        quickPick.title = args.title;
        quickPick.placeholder = args.placeholder;
        
        let lastActiveItem = null;
        let autoExecuteTimer = null;
        const TIMEOUT_MS = 500;  // Timeout in milliseconds
        
        // Filter items based on input
        quickPick.onDidChangeValue((value) => {
          if (autoExecuteTimer) {
            clearTimeout(autoExecuteTimer);
          }
          
          // Get filtered items that match the input
          const matchingItems = quickPick.items.filter(item => 
            item.label.toLowerCase().startsWith(value.toLowerCase())
          );
          
          // If we have exactly one match and it's a leaf node
          if (matchingItems.length === 1 && !matchingItems[0].isGroup) {
            autoExecuteTimer = setTimeout(async () => {
              const item = matchingItems[0];
              if (item.action) {
                await vscode.commands.executeCommand(item.action);
                quickPick.hide();
                quickPick.dispose();
              }
            }, TIMEOUT_MS);
          }
        });
        
        quickPick.onDidChangeActive((items) => {
          const active = items[0];
          if (!active || active === lastActiveItem) return;
          lastActiveItem = active;
          
          // Auto-execute for leaf nodes (non-groups)
          if (active.action && !active.isGroup) {
            vscode.commands.executeCommand(active.action).then(() => {
              quickPick.hide();
              quickPick.dispose();
            });
          }
        });
        
        quickPick.onDidAccept(async () => {
          if (autoExecuteTimer) {
            clearTimeout(autoExecuteTimer);
          }
          
          const selected = quickPick.selectedItems[0];
          if (!selected) return;
          
          if (selected.isGroup) {
            return;
          }

          if (selected.action) {
            await vscode.commands.executeCommand(selected.action);
          }
          quickPick.hide();
          quickPick.dispose();
        });
        
        quickPick.onDidHide(() => {
          if (autoExecuteTimer) {
            clearTimeout(autoExecuteTimer);
          }
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

    -- Format menu items for a specific group
    local function format_menu_items(group)
      local items = {}
      for _, binding in ipairs(group.bindings) do
        table.insert(items, {
          label = binding.key,
          description = binding.description,
          action = binding.action,
          key = binding.key,
          isGroup = false,  -- Explicitly mark as non-group item
          isGroupItem = false  -- Explicitly mark as non-group item
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

      for key, group in pairs(keybindings) do
        if lastCategory then
          table.insert(items, {
            label = "──────────────",
            kind = -1,
            isGroup = false,
            isGroupItem = false
          })
        end
        -- Add the group header
        table.insert(items, {
          label = key,
          description = group.name,
          key = key,
          isGroup = true,
          isGroupItem = false
        })
        -- Add the group's bindings
        for _, binding in ipairs(group.bindings) do
          table.insert(items, {
            label = key .. binding.key,
            description = binding.description,
            action = binding.action,
            key = binding.key,
            isGroup = false,
            isGroupItem = true
          })
        end
        lastCategory = key
      end

      cache.root_items = items
      return items
    end

    -- Show the which-key menu for a group or the root menu
    local function show_menu(group)
      local ok, items = pcall(function()
        return group and format_menu_items(group) or format_root_menu_items()
      end)
      
      if not ok then
        vim.notify("Error formatting menu items: " .. tostring(items), vim.log.levels.ERROR)
        return
      end
      
      local title = group and group.name or "Which Key Menu"
      local placeholder = group
        and "Select an action or press <Esc> to cancel"
        or "Select a group or action (groups shown with ▸)"

      -- Optional: write to prompt file for debugging
      -- write_prompt(title, placeholder, items)

      local eval_ok, eval_err = pcall(vscode.eval, EVAL_STRINGS.quickpick_menu, {
        timeout = 1000,
        args = {
          items = items,
          title = title,
          placeholder = placeholder,
        }
      })
      
      if not eval_ok then
        vim.notify("Error showing which-key menu: " .. tostring(eval_err), vim.log.levels.ERROR)
      end
    end

    -- Hide the which-key menu
    local function hide_menu()
      pcall(vscode.eval, EVAL_STRINGS.hide_quickpick, { timeout = 1000 })
    end

    -- Handle a specific key group
    local function handle_group(prefix, group)
      vim.keymap.set("n", prefix, function()
        show_menu(group)
      end, { noremap = true, silent = true })

      for _, binding in ipairs(group.bindings) do
        vim.keymap.set("n", prefix .. binding.key, function()
          hide_menu()
          pcall(vscode.action, binding.action)
        end, { noremap = true, silent = true })
      end
    end

    -- Update the mode display in the VSCode status bar
    local function update_mode_display()
      local full_mode = vim.api.nvim_get_mode().mode
      local mode_key = full_mode:sub(1,1)
      if mode_key == last_mode then return end
      local mode_data = MODE_DISPLAY[mode_key] or MODE_DISPLAY.n
      pcall(vscode.eval, EVAL_STRINGS.mode_display, {
        timeout = 1000,
        args = {
          text = mode_strings[mode_key] or mode_strings.n,
          color = mode_data.color,
          mode = mode_key
        }
      })
      last_mode = mode_key
    end

    -- Setup which-key menu system
    local function setup()
      -- Show root menu when leader is pressed
      vim.keymap.set("n", "<leader>", function()
        show_menu()
      end, { noremap = true, silent = true, desc = "Show which-key menu" })

      -- Setup each group
      for prefix, group in pairs(keybindings) do
        handle_group("<leader>" .. prefix, group)
      end

      -- Auto-hide menu on mode change or cursor move
      vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved" }, {
        callback = hide_menu,
      })

      -- Update mode display in status bar
      vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = update_mode_display,
      })

      -- Update mode display when entering command mode
      vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = function()
          pcall(vscode.eval, EVAL_STRINGS.mode_display, {
            timeout = 1000,
        args = {
          text = "COMMAND",
          color = MODE_DISPLAY.c.color,
          mode = 'c',
        }
          })
        end,
      })

      -- Initialize mode display
      update_mode_display()
    end

    return {
      setup = setup,
      update_mode_display = update_mode_display,
      show_menu = show_menu,
      hide_menu = hide_menu
    }
  end)()

  -- =============================================
  -- Common Keybindings
  -- =============================================
  local opts = { noremap = true, silent = true }

  -- Window navigation
  vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end, opts)
  vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.focusDownGroup") end, opts)
  vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.focusUpGroup") end, opts)
  vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, opts)

  -- Common commands
  map_cmd("n", "<leader>w", "w", opts)
  map_cmd("n", "<leader>wa", "wa", opts)

  -- Splits
  map_cmd("n", "<leader>\\\\", "vsplit", opts)
  map_cmd("n", "<leader>-", "split", opts)

  -- Code navigation
  vim.keymap.set("n", "gd", function() vscode.action("editor.action.revealDefinition") end, opts)
  vim.keymap.set("n", "gr", function() vscode.action("editor.action.goToReferences") end, opts)
  vim.keymap.set("n", "gi", function() vscode.action("editor.action.goToImplementation") end, opts)
  vim.keymap.set("n", "K", function() vscode.action("editor.action.showHover") end, opts)

  -- Comments
  vim.keymap.set("n", "gcc", function() vscode.action("editor.action.commentLine") end, opts)
  vim.keymap.set("v", "gc", function() vscode.action("editor.action.commentLine") end, opts)

  -- Return to editor / escape terminal
  vim.keymap.set("n", "<Esc><Esc>", function() vscode.action("workbench.action.focusActiveEditorGroup") end, opts)
  vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], opts)

  -- Better scrolling
  vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
  vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
  vim.keymap.set("n", "n", "nzzzv", opts)
  vim.keymap.set("n", "N", "Nzzzv", opts)

  -- Initialize which-key
  which_key.setup()
end

-- Main initialization function
local function init()
  -- If running under VSCode, override notifications to use VSCode UI
  if vim.g.vscode then
    local ok, vscode_mod = pcall(require, "vscode")
    if ok and vscode_mod.notify then
      vim.notify = vscode_mod.notify
    end
  end
  
  -- Basic initialization - works even if subsequent steps fail
  setup_leader()
  setup_common_settings()
  setup_vscode_integration()
  
  -- Try to load plugins (may fail if modules aren't available)
  pcall(setup_plugins)
  
  -- Set up VSCode-specific features when the VSCode UI attaches
  if vim.g.vscode then
    vim.api.nvim_create_autocmd("UIEnter", {
      once = true, 
      callback = function()
        local ok, err = pcall(setup_vscode_features)
        if not ok then
          vim.notify("Error loading VSCode features: " .. tostring(err), vim.log.levels.ERROR)
        end
      end,
    })
  end
end

-- Safeguard for ephemeral buffers
local function is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted")
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