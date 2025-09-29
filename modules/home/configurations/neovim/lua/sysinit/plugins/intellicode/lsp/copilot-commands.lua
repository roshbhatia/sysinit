local M = {}

function M.setup_commands()
  -- Copilot sign-in command
  vim.api.nvim_create_user_command("CopilotSignIn", function()
    local ok, copilot_lsp = pcall(require, "copilot-lsp")
    if not ok then
      vim.notify("Copilot LSP not available", vim.log.levels.ERROR)
      return
    end

    -- Check if already signed in
    local status = copilot_lsp.status()
    if status == "SignedIn" then
      vim.notify("Already signed in to Copilot", vim.log.levels.INFO)
      return
    end

    -- Start sign-in process
    vim.notify("Starting Copilot sign-in process...", vim.log.levels.INFO)
    
    -- Use the copilot-lsp sign-in functionality
    local auth = require("copilot-lsp.auth")
    auth.sign_in(function(success, message)
      if success then
        vim.notify("Successfully signed in to Copilot!", vim.log.levels.INFO)
        -- Restart the copilot-lsp server
        vim.cmd("LspRestart copilot_ls")
      else
        vim.notify("Failed to sign in to Copilot: " .. (message or "Unknown error"), vim.log.levels.ERROR)
      end
    end)
  end, {
    desc = "Sign in to GitHub Copilot",
  })

  -- Copilot status command
  vim.api.nvim_create_user_command("CopilotStatus", function()
    local ok, copilot_lsp = pcall(require, "copilot-lsp")
    if not ok then
      vim.notify("Copilot LSP not available", vim.log.levels.ERROR)
      return
    end

    local status = copilot_lsp.status()
    local status_messages = {
      SignedIn = "✅ Signed in to Copilot",
      SignedOut = "❌ Signed out of Copilot",
      NotAuthorized = "⚠️ Not authorized - please sign in",
      NetworkError = "🌐 Network error - check connection",
      Unknown = "❓ Unknown status"
    }

    local message = status_messages[status] or ("❓ Status: " .. tostring(status))
    vim.notify(message, vim.log.levels.INFO)
  end, {
    desc = "Check Copilot authentication status",
  })

  -- Copilot sign-out command
  vim.api.nvim_create_user_command("CopilotSignOut", function()
    local ok, copilot_lsp = pcall(require, "copilot-lsp")
    if not ok then
      vim.notify("Copilot LSP not available", vim.log.levels.ERROR)
      return
    end

    local auth = require("copilot-lsp.auth")
    auth.sign_out(function(success, message)
      if success then
        vim.notify("Successfully signed out of Copilot", vim.log.levels.INFO)
        -- Restart the copilot-lsp server
        vim.cmd("LspRestart copilot_ls")
      else
        vim.notify("Failed to sign out of Copilot: " .. (message or "Unknown error"), vim.log.levels.ERROR)
      end
    end)
  end, {
    desc = "Sign out of GitHub Copilot",
  })
end

return M