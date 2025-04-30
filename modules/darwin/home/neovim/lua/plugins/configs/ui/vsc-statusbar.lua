local vscode = require('vscode')
local M = {}

local MODE_DISPLAY = {
    n = {
        text = '󱄅 NORMAL',
        color = '#7aa2f7'
    },
    i = {
        text = ' INSERT',
        color = '#9ece6a'
    },
    v = {
        text = '󰈈 VISUAL',
        color = '#bb9af7'
    },
    V = {
        text = '󱣾 V-LINE',
        color = '#bb9af7'
    },
    ['\22'] = {
        text = '󰮔 V-BLOCK',
        color = '#bb9af7'
    },
    R = {
        text = '󰛔 REPLACE',
        color = '#f7768e'
    },
    s = {
        text = '󰴱 SELECT',
        color = '#ff9e64'
    },
    S = {
        text = '󰫙 S-LINE',
        color = '#ff9e64'
    },
    ['\19'] = {
        text = '󰩬 S-BLOCK',
        color = '#ff9e64'
    },
    c = {
        text = ' COMMAND',
        color = '#7dcfff'
    },
    t = {
        text = ' TERMINAL',
        color = '#73daca'
    }
}

local mode_strings = {}
local last_mode = nil

for mode, data in pairs(MODE_DISPLAY) do
    mode_strings[mode] = data.text
end

local STATUSBAR_JS = [[
  // Create or reuse the statusbar item
  if (!globalThis.modeStatusBar) {
    globalThis.modeStatusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
  }
  
  const statusBar = globalThis.modeStatusBar;
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
  
  // Ensure visibility
  statusBar.show();
  
  // Setup automatic refresh mechanism
  if (!globalThis.statusBarRefreshInterval) {
    globalThis.statusBarRefreshInterval = setInterval(() => {
      if (statusBar && !statusBar.visible) {
        statusBar.show();
      }
    }, 1000); // Check every second
  }
]]

local STATUSBAR_DISPOSE_JS = [[
  if (globalThis.statusBarRefreshInterval) {
    clearInterval(globalThis.statusBarRefreshInterval);
    globalThis.statusBarRefreshInterval = null;
  }
  
  if (globalThis.modeStatusBar) {
    globalThis.modeStatusBar.dispose();
    globalThis.modeStatusBar = null;
  }
]]

function M.update_mode_display()
    local full_mode = vim.api.nvim_get_mode().mode
    local mode_key = full_mode:sub(1, 1)
    if mode_key == last_mode then
        pcall(vscode.eval, [[
      if (globalThis.modeStatusBar && !globalThis.modeStatusBar.visible) {
        globalThis.modeStatusBar.show();
      }
    ]], {
            timeout = 500
        })
        return
    end

    local mode_data = MODE_DISPLAY[mode_key] or MODE_DISPLAY.n
    pcall(vscode.eval, STATUSBAR_JS, {
        timeout = 1000,
        args = {
            text = mode_strings[mode_key] or mode_strings.n,
            color = mode_data.color,
            mode = mode_key
        }
    })
    last_mode = mode_key
end

function M.set_command_mode()
    pcall(vscode.eval, STATUSBAR_JS, {
        timeout = 1000,
        args = {
            text = MODE_DISPLAY.c.text,
            color = MODE_DISPLAY.c.color,
            mode = 'c'
        }
    })
end

function M.force_refresh()
    M.update_mode_display()
end

function M.setup()
    vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*",
        callback = M.update_mode_display
    })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = M.set_command_mode
    })

    vim.api.nvim_create_autocmd({"BufEnter", "WinEnter", "FocusGained", "VimResized"}, {
        callback = M.force_refresh
    })

    local timer = vim.loop.new_timer()
    timer:start(2000, 2000, vim.schedule_wrap(function()
        M.force_refresh()
    end))

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            timer:stop()
            timer:close()
            pcall(vscode.eval, STATUSBAR_DISPOSE_JS, {
                timeout = 500
            })
        end
    })

    M.update_mode_display()
end

return M
