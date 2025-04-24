-- This file helps debug why VSCode-Neovim integration isn't working
local M = {}

function M.debug()
  -- Check if running inside VSCode
  local is_vscode = vim.g.vscode or (vim.env.VSCODE_GIT_IPC_HANDLE and vim.env.VSCODE_GIT_ASKPASS_NODE)
  
  print("Is running in VSCode: " .. tostring(is_vscode))
  
  -- Try to load the VSCode module
  local vscode_ok, vscode = pcall(require, "vscode")
  print("VSCode module load status: " .. tostring(vscode_ok))
  
  if vscode_ok then
    print("VSCode module type: " .. type(vscode))
    print("Available methods:")
    for k, v in pairs(vscode) do
      print("  - " .. k .. " (" .. type(v) .. ")")
    end
    
    -- Try to call a simple VSCode API
    local notify_ok, notify_err = pcall(vscode.notify, "VSCode API test")
    print("Notify API call: " .. tostring(notify_ok) .. (notify_err and " - " .. tostring(notify_err) or ""))
    
    -- Try to execute a command
    local action_ok, action_err = pcall(vscode.action, "workbench.action.showCommands")
    print("Action API call: " .. tostring(action_ok) .. (action_err and " - " .. tostring(action_err) or ""))
    
    -- Try to evaluate JavaScript
    local eval_ok, eval_err = pcall(vscode.eval, "console.log('Hello from VSCode JavaScript')")
    print("Eval API call: " .. tostring(eval_ok) .. (eval_err and " - " .. tostring(eval_err) or ""))
  end
  
  -- Check if we have RPC channel
  local rpc_ok, rpc_err = pcall(function() 
    local channel_id = vim.fn.jobstart({'invali