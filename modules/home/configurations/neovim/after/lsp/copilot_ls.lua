local function setup(client, bufnr)
  local au = vim.api.nvim_create_augroup("copilotlsp.init", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local td_params = vim.lsp.util.make_text_document_params()
      client:notify("textDocument/didFocus", {
        textDocument = {
          uri = td_params.uri,
        },
      })
    end,
    group = au,
    buffer = bufnr,
  })

  suppress_limit_notifications()
  setup_commands()
end

local function get_copilot_client()
  local clients = vim.lsp.get_clients({ name = "copilot_ls" })
  if #clients > 0 then
    return clients[1]
  end
  return nil
end

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
        "Copied your one-time code to clipboard.\n" .. "Open the browser to complete the sign-in process?",
        "&Yes\n&No"
      )
      if continue == 1 then
        client:exec_cmd(command, { bufnr = bufnr }, function(cmd_err, cmd_result)
          if cmd_err then
            vim.notify(cmd_err.message, vim.log.levels.ERROR)
            return
          end
          if cmd_result and cmd_result.status == "OK" then
            vim.notify("Signed in as " .. (cmd_result.user or "unknown") .. ".")
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

local function sign_out(client)
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

function suppress_limit_notifications()
  local original_request_handler = vim.lsp.handlers["window/showMessageRequest"]
  vim.lsp.handlers["window/showMessageRequest"] = function(err, result, ctx, config)
    if result and result.message and result.message:match("reached your monthly code completion limit") then
      vim.notify(result.message, vim.log.levels.WARN)
      if result.actions and #result.actions > 0 then
        return result.actions[2]
      end
      return nil
    end
    return original_request_handler(err, result, ctx, config)
  end
end

function setup_commands()
  vim.api.nvim_create_user_command("CopilotSignIn", function()
    local client = get_copilot_client()
    if not client then
      vim.notify("Copilot LSP client not found. Make sure copilot_ls is running.", vim.log.levels.ERROR)
      return
    end

    sign_in(0, client)
  end, {
    desc = "Sign in to GitHub Copilot",
  })

  vim.api.nvim_create_user_command("CopilotSignOut", function()
    local client = get_copilot_client()
    if not client then
      vim.notify("Copilot LSP client not found. Make sure copilot_ls is running.", vim.log.levels.ERROR)
      return
    end

    sign_out(client)
  end, {
    desc = "Sign out of GitHub Copilot",
  })

  vim.api.nvim_create_user_command("CopilotStatus", function()
    local client = get_copilot_client()
    if not client then
      vim.notify("Copilot LSP client not found. Make sure copilot_ls is running.", vim.log.levels.ERROR)
      return
    end

    local has_pending_signin = false
    for _, req in pairs(client.requests) do
      if req.method == "signIn" and req.type == "pending" then
        has_pending_signin = true
        break
      end
    end

    if has_pending_signin then
      vim.notify("Sign-in in progress...", vim.log.levels.INFO)
    else
      vim.notify("Copilot LSP client is running. Use :CopilotSignIn to authenticate.", vim.log.levels.INFO)
    end
  end, {
    desc = "Check Copilot authentication status",
  })
end

return {
  on_attach = function(client, bufnr)
    setup(client, bufnr)
  end,
}
