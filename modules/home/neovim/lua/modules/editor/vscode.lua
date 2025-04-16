-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/vscode-neovim/vscode-neovim/main/README.md"
local M = {}

M.plugins = {
  {
    "vscode-neovim/vscode-neovim",
    lazy = false,
    cond = function()
      return vim.g.vscode == true
    end
  }
}

function M.setup_compat_plugins()
  if not vim.g.vscode then
    return
  end

  local vscode = require('vscode')
  local mode_strings = {}
  local last_mode = nil
  
  M.MODE_DISPLAY = {
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
    t = { text = 'TERMINAL', color = '#73daca' }
  }
  
  M.EVAL_STRINGS = {
    mode_display = [[
      if (globalThis.modeStatusBar) { globalThis.modeStatusBar.dispose(); }
      const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
      statusBar.text = args.text;
      statusBar.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
      statusBar.color = args.color;
      statusBar.show();
      globalThis.modeStatusBar = statusBar;
    ]],
    quickpick_menu = [[
      if (globalThis.quickPick) { globalThis.quickPick.dispose(); }
      const quickPick = vscode.window.createQuickPick();
      quickPick.items = args.items.map(item => ({
        label: item.isGroup ? `$(chevron-right) ${item.label}` : item.isGroupItem ? `  $(key) ${item.label}` : `$(key) ${item.label}`,
        description: item.description,
        action: item.action,
        key: item.key
      }));
      quickPick.title = args.title;
      quickPick.placeholder = args.placeholder;
      quickPick.onDidAccept(() => {
        const selected = quickPick.selectedItems[0];
        if (selected && selected.action) { vscode.commands.executeCommand(selected.action); }
        quickPick.hide();
        quickPick.dispose();
      });
      quickPick.onDidHide(() => quickPick.dispose());
      globalThis.quickPick = quickPick;
      quickPick.show();
    ]],
    hide_quickpick = [[
      if (globalThis.quickPick) {
        globalThis.quickPick.hide();
        globalThis.quickPick.dispose();
        globalThis.quickPick = undefined;
      }
    ]]
  }
  
  M.menu_cache = {
    root_items = nil,
    group_items = {}
  }
  
  M.keybindings = {
    f = {
      name = "🔍 Find",
      bindings = {
        { key = "f", description = "Find Files", action = "workbench.action.quickOpen" },
        { key = "g", description = "Live Grep", action = "workbench.action.findInFiles" },
        { key = "b", description = "Find Buffers", action = "workbench.action.showAllEditors" },
        { key = "s", description = "Find Symbols", action = "workbench.action.showAllSymbols" },
        { key = "r", description = "Recent Files", action = "workbench.action.openRecent" }
      }
    },
    w = {
      name = "🪟 Window",
      bindings = {
        { key = "h", description = "Focus Left", action = "workbench.action.focusLeftGroup" },
        { key = "j", description = "Focus Down", action = "workbench.action.focusDownGroup" },
        { key = "k", description = "Focus Up", action = "workbench.action.focusUpGroup" },
        { key = "l", description = "Focus Right", action = "workbench.action.focusRightGroup" },
        { key = "=", description = "Equal Width", action = "workbench.action.evenEditorWidths" },
        { key = "_", description = "Max Width", action = "workbench.action.toggleEditorWidths" },
        { key = "w", description = "Close Editor", action = "workbench.action.closeActiveEditor" },
        { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" },
        { key = "H", description = "Move Left", action = "workbench.action.moveEditorToLeftGroup" },
        { key = "J", description = "Move Down", action = "workbench.action.moveEditorToBelowGroup" },
        { key = "K", description = "Move Up", action = "workbench.action.moveEditorToAboveGroup" },
        { key = "L", description = "Move Right", action = "workbench.action.moveEditorToRightGroup" }
      }
    },
    u = {
      name = "⚙️ UI",
      bindings = {
        { key = "a", description = "Activity Bar", action = "workbench.action.toggleActivityBarVisibility" },
        { key = "s", description = "Status Bar", action = "workbench.action.toggleStatusbarVisibility" },
        { key = "t", description = "Tab Bar", action = "workbench.action.toggleTabsVisibility" },
        { key = "b", description = "Side Bar", action = "workbench.action.toggleSidebarVisibility" },
        { key = "z", description = "Zen Mode", action = "workbench.action.toggleZenMode" },
        { key = "f", description = "Full Screen", action = "workbench.action.toggleFullScreen" }
      }
    },
    b = {
      name = "📝 Buffer",
      bindings = {
        { key = "n", description = "Next Buffer", action = "workbench.action.nextEditor" },
        { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
        { key = "d", description = "Close Buffer", action = "workbench.action.closeActiveEditor" },
        { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" }
      }
    },
    g = {
      name = "🔄 Git",
      bindings = {
        { key = "b", description = "Git Blame", action = "gitlens.toggleLineBlame" },
        { key = "d", description = "Git Diff", action = "git.openChange" },
        { key = "s", description = "Git Status", action = "workbench.scm.focus" },
        { key = "c", description = "Git Commit", action = "git.commitAll" },
        { key = "p", description = "Git Push", action = "git.push" },
        { key = "m", description = "Generate Commit Message", action = "github.copilot.generateCommitMessage" }
      }
    },
    c = {
      name = "💻 Code",
      bindings = {
        { key = "a", description = "Code Actions", action = "editor.action.quickFix" },
        { key = "r", description = "Rename Symbol", action = "editor.action.rename" },
        { key = "f", description = "Format Document", action = "editor.action.formatDocument" },
        { key = "d", description = "Go to Definition", action = "editor.action.revealDefinition" },
        { key = "i", description = "Go to Implementation", action = "editor.action.goToImplementation" },
        { key = "h", description = "Show Hover", action = "editor.action.showHover" },
        { key = "c", description = "Toggle Comment", action = "editor.action.commentLine" }
      }
    },
    t = {
      name = "🔧 Toggle",
      bindings = {
        { key = "e", description = "󰏖 Explorer", action = "workbench.view.explorer" },
        { key = "t", description = "󰙅 Terminal", action = "workbench.action.terminal.toggleTerminal" },
        { key = "p", description = "󰏘 Problems", action = "workbench.actions.view.problems" },
        { key = "o", description = "󰙀 Outline", action = "outline.focus" },
        { key = "c", description = "󰚩 Copilot Chat", action = "github.copilot.chat.focus" },
        { key = "b", description = "󰌽 Return to Editor", action = "workbench.action.focusActiveEditorGroup" },
        { key = "m", description = "⌘ Command Palette", action = "workbench.action.showCommands" }
      }
    },
    a = {
      name = "🛠 AI",
      bindings = {
        { key = "c", description = "Start Copilot Chat", action = "github.copilot.chat.focus" },
        { key = "i", description = "Inline Chat", action = "inlineChat.start" },
        { key = "g", description = "Explain Code", action = "codegpt.explainCodeGPT" },
        { key = "d", description = "Add Doc Comments", action = "extension.addDocComments" },
        { key = "t", description = "Toggle Copilot", action = "github.copilot.toggleCopilot" }
      }
    }
  }
  
  for mode, data in pairs(M.MODE_DISPLAY) do
    mode_strings[mode] = string.format("Mode: %s", data.text)
  end

  local function update_mode_display()
    local current_mode = vim.api.nvim_get_mode().mode
    if current_mode == last_mode then return end
    
    local mode_data = M.MODE_DISPLAY[current_mode] or M.MODE_DISPLAY.n
    vscode.eval(M.EVAL_STRINGS.mode_display, {
      timeout = 1000,
      args = {
        text = mode_strings[current_mode] or mode_strings.n,
        color = mode_data.color
      }
    })
    last_mode = current_mode
  end

  local function format_menu_items(group)
    local items = {}
    for _, binding in ipairs(group.bindings) do
      table.insert(items, {
        label = binding.key,
        description = binding.description,
        action = binding.action
      })
    end
    return items
  end

  local function format_root_menu_items()
    if M.menu_cache.root_items then
      return M.menu_cache.root_items
    end
    
    local items = {}
    for key, group in pairs(M.keybindings) do
      table.insert(items, {
        label = key,
        description = group.name,
        isGroup = true,
        key = key
      })
      
      for _, binding in ipairs(group.bindings) do
        table.insert(items, {
          label = key .. binding.key,
          description = binding.description,
          action = binding.action,
          isGroupItem = true
        })
      end
    end
    
    M.menu_cache.root_items = items
    return items
  end

  local function show_menu(group)
    local items
    if group then
      items = format_menu_items(group)
    else
      items = format_root_menu_items()
    end
    
    vscode.eval(M.EVAL_STRINGS.quickpick_menu, { 
      timeout = 1000,
      args = { 
        items = items,
        title = group and group.name or "Which Key Menu",
        placeholder = group 
          and 'Select an action or press <Esc> to cancel'
          or 'Select a group or action (groups shown with ▸)'
      }
    })
  end

  local function hide_menu()
    vscode.eval(M.EVAL_STRINGS.hide_quickpick, { timeout = 1000 })
  end

  local function handle_group(prefix, group)
    vim.keymap.set("n", prefix, function()
      show_menu(group)
    end, { noremap = true, silent = true })

    for _, binding in ipairs(group.bindings) do
      vim.keymap.set("n", prefix .. binding.key, function()
        hide_menu()
        vscode.action(binding.action)
      end, { noremap = true, silent = true })
    end
  end

  vim.keymap.set("n", "<leader>", function()
    show_menu()
  end, { noremap = true, silent = true })

  for prefix, group in pairs(M.keybindings) do
    handle_group("<leader>" .. prefix, group)
  end

  vim.api.nvim_create_autocmd({"ModeChanged", "CursorMoved"}, {
    callback = hide_menu
  })

  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*',
    callback = update_mode_display
  })

  vim.api.nvim_create_autocmd('CmdlineEnter', {
    callback = function()
      vscode.eval(M.EVAL_STRINGS.mode_display, {
        timeout = 1000,
        args = {
          text = "COMMAND",
          color = M.MODE_DISPLAY.c.color
        }
      })
    end
  })

  local opts = { noremap = true, silent = true }

  vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end, opts)
  vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.focusDownGroup") end, opts)
  vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.focusUpGroup") end, opts)
  vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, opts)

  vim.keymap.set('n', '<leader>w', function() vscode.action('workbench.action.files.save') end, opts)
  vim.keymap.set('n', '<leader>wa', function() vscode.action('workbench.action.files.saveAll') end, opts)
  
  vim.keymap.set('n', '<leader>\\', function() vscode.action('workbench.action.splitEditorRight') end, opts)
  vim.keymap.set('n', '<leader>-', function() vscode.action('workbench.action.splitEditorDown') end, opts)

  vim.keymap.set('n', 'gd', function() vscode.action('editor.action.revealDefinition') end, opts)
  vim.keymap.set('n', 'gr', function() vscode.action('editor.action.goToReferences') end, opts)
  vim.keymap.set('n', 'gi', function() vscode.action('editor.action.goToImplementation') end, opts)
  vim.keymap.set('n', 'K', function() vscode.action('editor.action.showHover') end, opts)

  vim.keymap.set('n', 'gcc', function() vscode.action('editor.action.commentLine') end, opts)
  vim.keymap.set('v', 'gc', function() vscode.action('editor.action.commentLine') end, opts)

  vim.keymap.set('n', '<Esc><Esc>', function() vscode.action('workbench.action.focusActiveEditorGroup') end, opts)
  vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], opts)

  vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
  vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)
  vim.keymap.set('n', 'n', 'nzzzv', opts)
  vim.keymap.set('n', 'N', 'Nzzzv', opts)

  update_mode_display()
end

return M