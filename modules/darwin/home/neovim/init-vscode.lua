-- WARNING: AUTO-GENERATED FILE. DO NOT EDIT.
-- Template for VSCode Neovim init, based on init.lua

vim.g.vscode = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
local lua_dir = init_dir .. "/lua"
vim.opt.rtp:prepend(lua_dir)

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", ":", ":", { noremap = true, desc = "Command mode" })

-- Common settings
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

-- VSCode-specific settings
local function setup_vscode_settings()
  vim.notify("SysInit -- VSCode Neovim integration detected", vim.log.levels.INFO)
end

setup_common_settings()
setup_vscode_settings()

local module_loader = require("core.module_loader")

-- determine module loading system
local module_system = {
  editor = {
    "vscode",
  },
  ui = {
  },
  tools = {
  },
}

local function collect_plugin_specs()
  -- collect module plugin specs and add VSCode Neovim extension
  local specs = module_loader.get_plugin_specs(module_system)
  table.insert(specs, {
    "vscode-neovim/vscode-neovim",
    lazy = false,
    cond = function()
      return vim.g.vscode == true
    end,
  })
  return specs
end

require("lazy").setup(collect_plugin_specs())

module_loader.setup_modules(module_system)

-- VSCode Neovim compatibility: inline from lua/modules/editor/vscode.lua
-- 1) Map of Neovim commands to VSCode actions
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
 
-- Helper functions for file output and parity checking
local info = debug.getinfo(1, 'S')
local script_path = info.source:sub(2)
local script_dir = vim.fn.fnamemodify(script_path, ':p:h')
local root_dir = vim.fn.fnamemodify(script_dir .. '/../../../', ':p')
local utils = {
  prompt_file  = root_dir .. 'prompt.md',
  status_file  = root_dir .. 'status.md',
  actions_file = root_dir .. 'vscode/actions.txt',
}

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
  write_file(utils.prompt_file, lines)
end

local function write_status(entries)
  local lines = { '# VSCode Neovim Parity Status', '' }
  for _, e in ipairs(entries) do table.insert(lines, '- ' .. e) end
  write_file(utils.status_file, lines)
end

local function check_parity()
  local entries = {}
  local valid = {}
  local af = io.open(utils.actions_file, 'r')
  if af then
    for line in af:lines() do valid[line] = true end
    af:close()
  else
    table.insert(entries, 'Unable to open actions file: ' .. utils.actions_file)
    write_status(entries)
    return
  end
  for cmd, action in pairs(cmd_map) do
    if not valid[action] then
      local msg = string.format("Invalid action '%s' for command '%s'", action, cmd)
      vim.notify(msg, vim.log.levels.WARN)
      table.insert(entries, msg)
    end
  end
  for prefix, group in pairs(keybindings) do
    for _, b in ipairs(group.bindings) do
      if not valid[b.action or ''] then
        local msg = string.format("Invalid action '%s' in bindings for '%s'", b.action, prefix)
        vim.notify(msg, vim.log.levels.WARN)
        table.insert(entries, msg)
      end
    end
  end
  if #entries == 0 then table.insert(entries, 'All VSCode actions are valid.') end
  write_status(entries)
end

local function map_cmd(mode, lhs, cmd, opts)
  opts = opts or { noremap = true, silent = true }
  local action = cmd_map[cmd]
  if action then
    local api = require('vscode')
    vim.keymap.set(mode, lhs, function() api.action(action) end, opts)
  else
    vim.keymap.set(mode, lhs, '<cmd>' .. cmd .. '<cr>', opts)
  end
end

-- 2) Which-key style keybindings
local keybindings = {
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
      { key = "g", description = "Generate Commit", action = "workbench.action.chat.open" },
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

-- Inline VSCode compatibility logic

local vscode = require('vscode')
local mode_strings = {}
local last_mode = nil

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

local EVAL_STRINGS = {
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

local menu_cache = {
  root_items = nil,
  group_items = {}
}

for mode, data in pairs(MODE_DISPLAY) do
  mode_strings[mode] = string.format("Mode: %s", data.text)
end

local function update_mode_display()
  local current_mode = vim.api.nvim_get_mode().mode
  if current_mode == last_mode then return end
  local mode_data = MODE_DISPLAY[current_mode] or MODE_DISPLAY.n
  vscode.eval(EVAL_STRINGS.mode_display, {
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
      action = binding.action,
      key = binding.key,
    })
  end
  return items
end

local function format_root_menu_items()
  if menu_cache.root_items then
    return menu_cache.root_items
  end

  local items = {}
  local lastCategory = nil

  for key, group in pairs(keybindings) do
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

  menu_cache.root_items = items
  return items
end

local function show_menu(group)
  local items = group and format_menu_items(group) or format_root_menu_items()
  local title = group and group.name or "Which Key Menu"
  local placeholder = group
    and "Select an action or press <Esc> to cancel"
    or "Select a group or action (groups shown with ▸)"

  write_prompt(title, placeholder, items)

  vscode.eval(EVAL_STRINGS.quickpick_menu, {
    timeout = 1000,
    args = {
      items = items,
      title = title,
      placeholder = placeholder,
    }
  })
end

local function hide_menu()
  vscode.eval(EVAL_STRINGS.hide_quickpick, { timeout = 1000 })
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

for prefix, group in pairs(keybindings) do
  handle_group("<leader>" .. prefix, group)
end

vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved" }, {
  callback = hide_menu,
})

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = update_mode_display,
})

vim.api.nvim_create_autocmd("CmdlineEnter", {
  callback = function()
    vscode.eval(EVAL_STRINGS.mode_display, {
      timeout = 1000,
      args = {
        text = "COMMAND",
        color = MODE_DISPLAY.c.color,
      }
    })
  end,
})

local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end, opts)
vim.keymap.set("n", "<C-j>", function() vscode.action("workbench.action.focusDownGroup") end, opts)
vim.keymap.set("n", "<C-k>", function() vscode.action("workbench.action.focusUpGroup") end, opts)
vim.keymap.set("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, opts)

map_cmd("n", "<leader>w", "w", opts)
map_cmd("n", "<leader>wa", "wa", opts)

map_cmd("n", "<leader>\\\\", "vsplit", opts)
map_cmd("n", "<leader>-", "split", opts)

vim.keymap.set("n", "gd", function() vscode.action("editor.action.revealDefinition") end, opts)
vim.keymap.set("n", "gr", function() vscode.action("editor.action.goToReferences") end, opts)
vim.keymap.set("n", "gi", function() vscode.action("editor.action.goToImplementation") end, opts)
vim.keymap.set("n", "K", function() vscode.action("editor.action.showHover") end, opts)

vim.keymap.set("n", "gcc", function() vscode.action("editor.action.commentLine") end, opts)
vim.keymap.set("v", "gc", function() vscode.action("editor.action.commentLine") end, opts)

vim.keymap.set("n", "<Esc><Esc>", function() vscode.action("workbench.action.focusActiveEditorGroup") end, opts)
vim.keymap.set("t", "<Esc><Esc>", [[<C-\\><C-n>]], opts)

vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)

update_mode_display()
check_parity()