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

  local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
  local lua_dir = init_dir .. "/lua"
  vim.opt.rtp:prepend(lua_dir)
end

local function setup_leader()
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })
  
  vim.keymap.set("n", "<leader>;", function() 
    local vscode = require("vscode")
    vscode.action("workbench.action.showCommands")
  end, { noremap = true, silent = true })
end

local function setup_common_settings()
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true

  vim.opt.splitbelow = true
  vim.opt.splitright = true

  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"
end

local function setup_plugins()
  local ok, module_loader = pcall(require, "core.module_loader")
  if not ok then return end

  local module_system = {
    editor = { "vscode" },
    ui = {},
    tools = {},
  }

  local function collect_plugin_specs()
    local specs = module_loader.get_plugin_specs(module_system)
    table.insert(specs, {
      "vscode-neovim/vscode-neovim",
      lazy = false,
      cond = function() return true end,
    })
    return specs
  end

  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then return end

  lazy.setup(collect_plugin_specs())
  module_loader.setup_modules(module_system)
end

local function setup_vscode_features()
  local vscode_ok, vscode = pcall(require, "vscode")
  if not vscode_ok then return end

  local CommonMappings = {}
  local WhichKey = {}
  local CommandMapper = {}
  local ModeDisplayer = {}

  CommandMapper.map = {
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

  function CommandMapper.map_cmd(mode, lhs, cmd, opts)
    opts = opts or { noremap = true, silent = true }
    local action = CommandMapper.map[cmd]
    if action then
      vim.keymap.set(mode, lhs, function() vscode.action(action) end, opts)
    else
      vim.keymap.set(mode, lhs, '<cmd>' .. cmd .. '<cr>', opts)
    end
  end

  WhichKey.keybindings = {
    f = {
      name = "🗺️ Find",
      bindings = {
        { key = "f", description = "Find Files",    action = "search-preview.quickOpenWithPreview" },
        { key = "g", description = "Find in Files", action = "workbench.action.findInFiles" },
        { key = "b", description = "Find Buffers",  action = "workbench.action.showAllEditors" },
        { key = "s", description = "Find Symbols",  action = "workbench.action.showAllSymbols" },
        { key = "r", description = "Recent Files",  action = "workbench.action.openRecent" },
      },
    },
    w = {
      name = "🏰 Window",
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
      name = "🛡️ UI",
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
      name = "📜 Scroll",
      bindings = {
        { key = "n", description = "Next Buffer",     action = "workbench.action.nextEditor" },
        { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
        { key = "d", description = "Close Buffer",    action = "workbench.action.closeActiveEditor" },
        { key = "o", description = "Close Others",    action = "workbench.action.closeOtherEditors" },
      },
    },
    g = {
      name = "⚔️ Git",
      bindings = {
        { key = "s", description = "Stage Changes",           action = "git.stage" },
        { key = "S", description = "Stage All",               action = "git.stageAll" },
        { key = "u", description = "Unstage Changes",         action = "git.unstage" },
        { key = "U", description = "Unstage All",             action = "git.unstageAll" },
        { key = "c", description = "Commit",                  action = "git.commit" },
        { key = "C", description = "Commit All",              action = "git.commitAll" },
        { key = "p", description = "Push",                    action = "git.push" },
        { key = "P", description = "Pull",                    action = "git.pull" },
        { key = "d", description = "Open Change",             action = "git.openChange" },
        { key = "D", description = "Open All Changes",        action = "git.openAllChanges" },
        { key = "b", description = "Checkout Branch",         action = "git.checkout" },
        { key = "f", description = "Fetch",                   action = "git.fetch" },
        { key = "r", description = "Revert Change",           action = "git.revertChange" },
        { key = "v", description = "SCM View",                action = "workbench.view.scm" },
        { key = "m", description = "Generate Commit Message", action = "workbench.action.chat.open" },
      },
    },
    c = {
      name = "📖 Codex",
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
      name = "🧙 Toggle",
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
      name = "🧝 Assistant",
      bindings = {
        { key = "c", description = "Start Chat",      action = "workbench.action.chat.open" },
        { key = "i", description = "Inline Chat",     action = "inlineChat.start" },
        { key = "v", description = "View in Chat",    action = "inlineChat.viewInChat" },
        { key = "r", description = "Regenerate",      action = "inlineChat.regenerate" },
        { key = "a", description = "Accept Changes",  action = "inlineChat.acceptChanges" },
        { key = "g", description = "Generate Commit", action = "workbench.action.chat.open" },
      },
    },
    s = {
      name = "🗡️ Split",
      bindings = {
        { key = "s", description = "Stage Hunk",       action = "git.diff.stageHunk" },
        { key = "S", description = "Stage Selection",  action = "git.diff.stageSelection" },
        { key = "u", description = "Unstage",          action = "git.unstage" },
        { key = "h", description = "Split Horizontal", action = "workbench.action.splitEditorDown" },
        { key = "v", description = "Split Vertical",   action = "workbench.action.splitEditorRight" },
      },
    },
  }

  ModeDisplayer.modes = {
    n = { text = '🗡️ NORMAL', color = '#7aa2f7', cursorStyle = 'block', cursorColor = '#7aa2f7' },
    i = { text = '✒️ INSERT', color = '#9ece6a', cursorStyle = 'line', cursorColor = '#9ece6a' },
    v = { text = '🏹 VISUAL', color = '#bb9af7', cursorStyle = 'block', cursorColor = '#bb9af7' },
    V = { text = '⚔️ VISUAL LINE', color = '#bb9af7', cursorStyle = 'underline', cursorColor = '#bb9af7' },
    ['\22'] = { text = '🛡️ VISUAL BLOCK', color = '#bb9af7', cursorStyle = 'block', cursorColor = '#bb9af7' },
    R = { text = '🔮 REPLACE', color = '#f7768e', cursorStyle = 'underline', cursorColor = '#f7768e' },
    s = { text = '🧙 SELECT', color = '#ff9e64', cursorStyle = 'block', cursorColor = '#ff9e64' },
    S = { text = '🧝 SELECT LINE', color = '#ff9e64', cursorStyle = 'underline', cursorColor = '#ff9e64' },
    ['\19'] = { text = '💀 SELECT BLOCK', color = '#ff9e64', cursorStyle = 'block', cursorColor = '#ff9e64' },
    c = { text = '📜 COMMAND', color = '#7dcfff', cursorStyle = 'line', cursorColor = '#7dcfff' },
    t = { text = '🏰 TERMINAL', color = '#73daca', cursorStyle = 'line', cursorColor = '#73daca' },
  }

  ModeDisplayer.mode_strings = {}
  ModeDisplayer.last_mode = nil
  
  for mode, data in pairs(ModeDisplayer.modes) do
    ModeDisplayer.mode_strings[mode] = data.text
  end

  ModeDisplayer.js_mode_display = [[
    if (globalThis.modeStatusBar) { globalThis.modeStatusBar.dispose(); }
    
    const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBar.text = args.text;
    statusBar.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
    statusBar.color = args.color;
    statusBar.show();
    globalThis.modeStatusBar = statusBar;
    
    const editor = vscode.window.activeTextEditor;
    if (editor) {
      vscode.window.activeTextEditor.options = {
        cursorStyle: args.cursorStyle,
        cursorBlinking: 'solid'
      };
      
      vscode.workspace.getConfiguration().update('workbench.colorCustomizations', {
        "editorCursor.foreground": args.cursorColor
      }, vscode.ConfigurationTarget.Workspace);
    }
  ]]

  WhichKey.js_quickpick_menu = [[
    if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
    
    const quickPick = vscode.window.createQuickPick();
    
    quickPick.items = args.items.map(item => ({
      label: item.isGroup ? 
        `$(chevron-right) ${item.label}` : 
        item.isGroupItem ? 
          `    $(arrow-small-right) ${item.label}` : 
          `  $(key) ${item.label}`,
      description: item.description,
      action: item.action,
      key: item.key,
      kind: item.kind,
      iconPath: item.isGroup ? new vscode.ThemeIcon("folder") : undefined,
      buttons: item.action ? [{ iconPath: new vscode.ThemeIcon("run") }] : []
    }));
    
    quickPick.title = args.title;
    quickPick.placeholder = args.placeholder;
    quickPick.matchOnDescription = true;
    quickPick.matchOnDetail = true;
    
    quickPick.onDidAccept(() => {
      const selected = quickPick.selectedItems[0];
      if (selected && selected.action) {
        vscode.commands.executeCommand(selected.action);
      }
      quickPick.hide();
      quickPick.dispose();
    });
    
    quickPick.onDidTriggerItemButton(event => {
      if (event.item.action) {
        vscode.commands.executeCommand(event.item.action);
        quickPick.hide();
        quickPick.dispose();
      }
    });
    
    quickPick.onDidHide(() => {
      quickPick.dispose();
    });
    
    globalThis.quickPick = quickPick;
    quickPick.show();
  ]]

  WhichKey.js_hide_quickpick = [[
    if (globalThis.quickPick) {
      globalThis.quickPick.hide();
      globalThis.quickPick.dispose();
      globalThis.quickPick = undefined;
    }
  ]]

  WhichKey.cache = {
    root_items = nil,
    group_items = {}
  }

  function WhichKey.format_menu_items(group)
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

  function WhichKey.format_root_menu_items()
    if WhichKey.cache.root_items then
      return WhichKey.cache.root_items
    end

    local items = {}
    local lastCategory = nil

    for key, group in pairs(WhichKey.keybindings) do
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

    WhichKey.cache.root_items = items
    return items
  end

  function WhichKey.show_menu(group)
    local ok, items = pcall(function()
      return group and WhichKey.format_menu_items(group) or WhichKey.format_root_menu_items()
    end)
    
    if not ok then return end
    
    local title = group and group.name or "🗡️ Command Menu"
    local placeholder = group
      and "Select an action or press <Esc> to cancel"
      or "Select a group or action (groups shown with ▸)"

    pcall(vscode.eval, WhichKey.js_quickpick_menu, {
      timeout = 1000,
      args = {
        items = items,
        title = title,
        placeholder = placeholder,
      }
    })
  end

  function WhichKey.hide_menu()
    pcall(vscode.eval, WhichKey.js_hide_quickpick, { timeout = 1000 })
  end

  function WhichKey.handle_group(prefix, group)
    vim.keymap.set("n", prefix, function()
      WhichKey.show_menu(group)
    end, { noremap = true, silent = true })

    for _, binding in ipairs(group.bindings) do
      vim.keymap.set("n", prefix .. binding.key, function()
        WhichKey.hide_menu()
        pcall(vscode.action, binding.action)
      end, { noremap = true, silent = true })
    end
  end

  function ModeDisplayer.update()
    local current_mode = vim.api.nvim_get_mode().mode
    if current_mode == ModeDisplayer.last_mode then return end
    local mode_data = ModeDisplayer.modes[current_mode] or ModeDisplayer.modes.n
    pcall(vscode.eval, ModeDisplayer.js_mode_display, {
      timeout = 1000,
      args = {
        text = ModeDisplayer.mode_strings[current_mode] or ModeDisplayer.mode_strings.n,
        color = mode_data.color,
        cursorStyle = mode_data.cursorStyle,
        cursorColor = mode_data.cursorColor
      }
    })
    ModeDisplayer.last_mode = current_mode
  end

  function WhichKey.setup()
    vim.keymap.set("n", "<leader>", function()
      WhichKey.show_menu()
    end, { noremap = true, silent = true })

    for prefix, group in pairs(WhichKey.keybindings) do
      WhichKey.handle_group("<leader>" .. prefix, group)
    end

    vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved" }, {
      callback = WhichKey.hide_menu,
    })

    vim.api.nvim_create_autocmd("ModeChanged", {
      pattern = "*",
      callback = ModeDisplayer.update,
    })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
      callback = function()
        pcall(vscode.eval, ModeDisplayer.js_mode_display, {
          timeout = 1000,
          args = {
            text = ModeDisplayer.modes.c.text,
            color = ModeDisplayer.modes.c.color,
            cursorStyle = ModeDisplayer.modes.c.cursorStyle,
            cursorColor = ModeDisplayer.modes.c.cursorColor
          }
        })
      end,
    })

    ModeDisplayer.update()
  end

  function CommonMappings.setup()
    local opts = { noremap = true, silent = true }

    vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end, opts)
    vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.focusDownGroup") end, opts)
    vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.focusUpGroup") end, opts)
    vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, opts)

    CommandMapper.map_cmd("n", "<leader>w", "w", opts)
    CommandMapper.map_cmd("n", "<leader>wa", "wa", opts)

    CommandMapper.map_cmd("n", "<leader>\\\\", "vsplit", opts)
    CommandMapper.map_cmd("n", "<leader>-", "split", opts)

    vim.keymap.set("n", "gd", function() vscode.action("editor.action.revealDefinition") end, opts)
    vim.keymap.set("n", "gr", function() vscode.action("editor.action.goToReferences") end, opts)
    vim.keymap.set("n", "gi", function() vscode.action("editor.action.goToImplementation") end, opts)
    vim.keymap.set("n", "K", function() vscode.action("editor.action.showHover") end, opts)

    vim.keymap.set("n", "gcc", function() vscode.action("editor.action.commentLine") end, opts)
    vim.keymap.set("v", "gc", function() vscode.action("editor.action.commentLine") end, opts)

    vim.keymap.set("n", "<Esc><Esc>", function() vscode.action("workbench.action.focusActiveEditorGroup") end, opts)
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], opts)

    vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
    vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
    vim.keymap.set("n", "n", "nzzzv", opts)
    vim.keymap.set("n", "N", "Nzzzv", opts)
  end

  CommonMappings.setup()
  WhichKey.setup()
end

setup_lazy()
setup_leader()
setup_common_settings()
setup_plugins()
setup_vscode_features()