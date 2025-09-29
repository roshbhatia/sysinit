local M = {}

local function get_copilot_client()
  local clients = vim.lsp.get_clients({ name = "copilot_ls" })
  if #clients > 0 then
    return clients[1]
  end
  return nil
end

local function open_signin_popup(code, url)
  local lines = {
    " [Copilot-lsp] ",
    "",
    " First copy your one-time code: ",
    "   " .. code .. " ",
    " In your browser, visit: ",
    "   " .. url .. " ",
    "",
    " ...waiting, it might take a while and ",
    " this popup will auto close once done... ",
  }
  local height, width =
    #lines, math.max(unpack(vim.tbl_map(function(line)
      return #line
    end, lines)))

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local winnr = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    style = "minimal",
    border = "single",
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    height = height,
    width = width,
  })
  vim.wo[winnr].winhighlight = "Normal:Normal"
  vim.wo[winnr].winblend = 0

  return function()
    vim.api.nvim_win_close(winnr, true)
  end
end

local function copy_to_clipboard(s)
  vim.fn.setreg("+", s)
  vim.fn.setreg("*", s)
end

function M.setup_commands()
  vim.api.nvim_create_user_command("CopilotSignIn", function()
    local client = get_copilot_client()
    if not client then
      vim.notify(
        "Copilot LSP client not found. Make sure copilot_ls is running.",
        vim.log.levels.ERROR
      )
      return
    end

    if vim.g.copilot_lsp_signin_pending then
      vim.notify("Sign-in already in progress...", vim.log.levels.WARN)
      return
    end

    vim.notify("Starting Copilot sign-in process...", vim.log.levels.INFO)

    client:request("signIn", vim.empty_dict(), function(err, result)
      if err then
        vim.notify(
          "Failed to start sign-in: " .. (err.message or "Unknown error"),
          vim.log.levels.ERROR
        )
        return
      end

      vim.g.copilot_lsp_signin_pending = true
      local close_signin_popup = open_signin_popup(result.userCode, result.verificationUri)
      copy_to_clipboard(result.userCode)

      client:exec_cmd(result.command, { bufnr = 0 }, function(cmd_err, cmd_res)
        vim.g.copilot_lsp_signin_pending = nil
        close_signin_popup()

        if cmd_err then
          vim.notify("Failed to open browser: " .. vim.inspect(cmd_err), vim.log.levels.WARN)
          return
        end
        if cmd_res.status == "OK" then
          vim.notify("Successfully signed in as: " .. cmd_res.user, vim.log.levels.INFO)
        else
          vim.notify("Failed to sign in: " .. vim.inspect(cmd_res), vim.log.levels.ERROR)
        end
      end)
    end)
  end, {
    desc = "Sign in to GitHub Copilot",
  })

  vim.api.nvim_create_user_command("CopilotSignOut", function()
    local client = get_copilot_client()
    if not client then
      vim.notify(
        "Copilot LSP client not found. Make sure copilot_ls is running.",
        vim.log.levels.ERROR
      )
      return
    end

    client:request("signOut", vim.empty_dict(), function(err, result)
      if err then
        vim.notify("Failed to sign out: " .. (err.message or "Unknown error"), vim.log.levels.ERROR)
        return
      end
      if result.status == "NotSignedIn" then
        vim.notify("Not signed in.", vim.log.levels.INFO)
      else
        vim.notify("Successfully signed out of Copilot", vim.log.levels.INFO)
      end
    end)
  end, {
    desc = "Sign out of GitHub Copilot",
  })

  vim.api.nvim_create_user_command("CopilotStatus", function()
    local client = get_copilot_client()
    if not client then
      vim.notify(
        "Copilot LSP client not found. Make sure copilot_ls is running.",
        vim.log.levels.ERROR
      )
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
