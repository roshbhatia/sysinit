-- Set VSCode flag
vim.g.vscode = true

-- Setup debug logging
local log_path = vim.fn.stdpath("data") .. "/vscode-debug.log"
local function log(message)
  local file = io.open(log_path, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S ") .. message .. "\n")
    file:close()
  end
  vim.notify(message)
end

log("Starting minimal VSCode initialization")

-- Basic settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })

log("Basic settings configured")

-- Check for VSCode API
local vscode_available = false
local vscode = nil

vim.api.nvim_create_autocmd({"VimEnter", "UIEnter"}, {
  callback = function()
    log("VimEnter/UIEnter event triggered - checking for VSCode")
    local ok, mod = pcall(require, "vscode")
    if ok then
      vscode = mod
      vscode_available = true
      log("VSCode module loaded successfully")
      
      -- Setup basic mode display in status bar
      vim.api.nvim_create_autocmd("ModeChanged", {
        callback = function()
          local mode = vim.api.nvim_get_mode().mode
          local mode_name = ({
            n = "NORMAL",
            i = "INSERT",
            v = "VISUAL",
            V = "V-LINE",
            ["\22"] = "V-BLOCK",
            c = "COMMAND",
            t = "TERMINAL",
          })[mode:sub(1,1)] or "NORMAL"
          
          log("Mode changed to: " .. mode_name)
          
          pcall(vscode.notify, "Mode: " .. mode_name)
        end
      })
      
      -- Setup leader menu
      vim.keymap.set("n", "<leader>", function()
        log("Leader key pressed - showing menu")
        
        local menu_items = {}
        -- Add some basic menu items
        for key, description in pairs({
          f = "Find Files",
          g = "Find in Files", 
          b = "Buffers",
          w = "Windows",
          c = "Code Actions",
          t = "Terminal"
        }) do
          table.insert(menu_items, {
            label = key,
            description = description,
          })
        end
        
        local js_code = [[
          const quickPick = vscode.window.createQuickPick();
          quickPick.items = args.items.map(item => ({
            label: item.label,
            description: item.description
          }));
          quickPick.title = "VSCode Commands";
          quickPick.show();
        ]]
        
        pcall(vscode.eval, js_code, {
          timeout = 3000,
          args = { items = menu_items }
        })
      end, { noremap = true, silent = true })
      
      log("Leader menu configured")
      
      -- Setup some basic mappings
      vim.keymap.set("n", "<leader>f", function()
        pcall(vscode.action, "workbench.action.quickOpen")
      end, { noremap = true, desc = "Find Files" })
      
      vim.keymap.set("n", "<leader>g", function()
        pcall(vscode.action, "workbench.action.findInFiles")
      end, { noremap = true, desc = "Find in Files" })
      
      log("Basic keybindings configured")
    else
      log("VSCode module NOT available: " .. tostring(mod))
    end
  end
})

-- Report status
vim.api.nvim_create_autocmd("CursorMoved", {
  once = true,
  callback = function()
    log("First cursor movement detected")
    vim.defer_fn(function()
      if vscode_available then
        log("VSCode integration is WORKING")
        pcall(vscode.notify, "VSCode integration active")
      else
        log("VSCode integration is NOT WORKING")
        vim.notify("VSCode integration failed to load. Check logs at: " .. log_path, vim.log.levels.ERROR)
      end
    end, 1000)
  end
})

log("Minimal initialization complete. Waiting for VSCode events.")
