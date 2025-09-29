local M = {}

-- Helper function to get the copilot-lsp client
local function get_copilot_client()
  local clients = vim.lsp.get_clients({ name = "copilot_ls" })
  if #clients > 0 then
    return clients[1]
  end
  return nil
end

-- Sign-in function based on nvim-lspconfig implementation
local function sign_in(bufnr, client)
  client:request("signIn", vim.empty_dict(), function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end

    if result.command then
      local code = result.userCode
      local command = result.command
      vim.fn.setreg("+", code)
      vim.fn.setreg("*", code)
      local continue = vim.fn.confirm(
        "Copied your one-time code to clipboard.\n"
          .. "Open the browser to complete the sign-in process?",
        "&Yes\n&No"
      )
      if continue == 1 then
        client:exec_cmd(command, { bufnr = bufnr }, function(cmd_err, cmd_result)
          if cmd_err then
            vim.notify(cmd_err.message, vim.log.levels.ERROR)
            return
          end
          if cmd_result.status == "OK" then
            vim.notify("Signed in as " .. cmd_result.user .. ".")
          end
        end)
      end
    end

    if result.status == "PromptUserDeviceFlow" then
      vim.notify("Enter your one-time code " .. result.userCode .. " in " .. result.verificationUri)
    elseif result.status == "AlreadySignedIn" then
      vim.notify("Already signed in as " .. result.user .. ".")
    end
  end)
end

-- Sign-out function based on nvim-lspconfig implementation
local function sign_out(bufnr, client)
  client:request("signOut", vim.empty_dict(), function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end
    if result.status == "NotSignedIn" then
      vim.notify("Not signed in.")
    else
      vim.notify("Successfully signed out of Copilot")
    end
  end)
end

function M.setup_commands()
  -- Copilot sign-in command
  vim.api.nvim_create_user_command("CopilotSignIn", function()
    local client = get_copilot_client()
    if not client then
      vim.notify(
        "Copilot LSP client not found. Make sure copilot_ls is running.",
        vim.log.levels.ERROR
      )
      return
    end

    sign_in(0, client)
  end, {
    desc = "Sign in to GitHub Copilot",
  })

  -- Copilot sign-out command
  vim.api.nvim_create_user_command("CopilotSignOut", function()
    local client = get_copilot_client()
    if not client then
      vim.notify(
        "Copilot LSP client not found. Make sure copilot_ls is running.",
        vim.log.levels.ERROR
      )
      return
    end

    sign_out(0, client)
  end, {
    desc = "Sign out of GitHub Copilot",
  })

  -- Copilot status command
  vim.api.nvim_create_user_command("CopilotStatus", function()
    local client = get_copilot_client()
    if not client then
      vim.notify(
        "Copilot LSP client not found. Make sure copilot_ls is running.",
        vim.log.levels.ERROR
      )
      return
    end

    -- Check if there are any pending requests
    local has_pending_signin = false
    for _, req in pairs(client.requests) do
      if req.method == "signIn" and req.type == "pending" then
        has_pending_signin = true
        break
      end
    end

    if has_pending_signin then
      vim.notify("🔄 Sign-in in progress...", vim.log.levels.INFO)
    else
      vim.notify(
        "ℹ️ Copilot LSP client is running. Use :CopilotSignIn to authenticate.",
        vim.log.levels.INFO
      )
    end
  end, {
    desc = "Check Copilot authentication status",
  })
end

return M
