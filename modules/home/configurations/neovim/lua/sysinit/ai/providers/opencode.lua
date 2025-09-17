-- OpenCode Provider
local M = {}
local client = require("sysinit.ai.core.client")
local protocol = require("sysinit.ai.core.protocol")

M.name = "opencode"
M.port = 9103
M.client = nil

function M.setup(opts)
  opts = opts or {}
  M.port = opts.port or M.port

  -- Get or create client
  M.client = client.get_client(M.name, {
    port = M.port,
    logger = opts.logger,
    sse_handler = M.handle_sse,
  })
end

function M.send_prompt(text, context)
  if not M.client then
    M.setup()
  end

  -- Create message with context
  local msg = protocol.create_prompt(text, context)

  -- Send to opencode
  M.client:send("prompt", msg, function(result, error)
    if error then
      vim.notify("OpenCode error: " .. vim.inspect(error), vim.log.levels.ERROR)
    end
  end)
end

function M.command(cmd)
  if not M.client then
    M.setup()
  end

  local msg = protocol.create_command(cmd)
  M.client:send("command", msg, function(result, error)
    if error then
      vim.notify("OpenCode command error: " .. vim.inspect(error), vim.log.levels.ERROR)
    end
  end)
end

function M.handle_sse(data)
  local event = protocol.parse_sse(data)
  if event then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "OpenCodeSSE",
      data = event,
    })

    -- Handle file changes intelligently
    if event.type == "file_changed" and event.data and event.data.file then
      M._handle_file_change(event.data.file, event.data)
    elseif event.type == "files_changed" and event.data and event.data.files then
      for _, file_data in ipairs(event.data.files) do
        M._handle_file_change(file_data.file or file_data, file_data)
      end
    end
  end
end

-- Handle individual file changes
function M._handle_file_change(file, data)
  vim.schedule(function()
    local buf = vim.fn.bufnr(file)
    if buf == -1 then
      return -- File not loaded in buffer
    end

    -- Check if buffer has modifications
    if vim.api.nvim_buf_get_option(buf, "modified") then
      -- Offer diff view
      vim.notify(
        string.format("OpenCode modified %s. Review changes?", vim.fn.fnamemodify(file, ":t")),
        vim.log.levels.INFO
      )

      vim.ui.select({ "Open Diff", "Reload", "Ignore" }, {
        prompt = "File modified by OpenCode:",
      }, function(choice)
        if choice == "Open Diff" then
          M._open_diffview(file)
        elseif choice == "Reload" then
          vim.cmd("edit! " .. vim.fn.fnameescape(file))
        end
      end)
    else
      -- Auto-reload clean buffers
      vim.cmd("checktime " .. buf)
      vim.notify(
        string.format("Reloaded %s (modified by OpenCode)", vim.fn.fnamemodify(file, ":t")),
        vim.log.levels.INFO
      )
    end
  end)
end

-- Open diff view for file changes
function M._open_diffview(file)
  -- Try diffview.nvim first
  local diffview_ok, _ = pcall(require, "diffview")
  if diffview_ok then
    vim.cmd("DiffviewOpen HEAD~1 -- " .. vim.fn.fnameescape(file))
    return
  end

  -- Fallback: create a simple diff split
  local current_buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buf)

  if current_file == file then
    -- Create git show of previous version
    local git_content = vim.fn.system("git show HEAD:" .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      vim.cmd("vsplit")
      local new_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(0, new_buf)
      vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(git_content, "\n"))
      vim.bo[new_buf].filetype = vim.bo[current_buf].filetype
      vim.bo[new_buf].buftype = "nofile"
      vim.cmd("diffthis")
      vim.cmd("wincmd p")
      vim.cmd("diffthis")
    end
  end
end

function M.get_status()
  return {
    connected = M.client and M.client.state == "connected",
    port = M.port,
    name = M.name,
  }
end

return M
