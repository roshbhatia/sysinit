local M = {}

M.client = require("sysinit.ai.core.client")
M.server = require("sysinit.ai.core.server")
M.logger = require("sysinit.ai.core.logger")
M.protocol = require("sysinit.ai.core.protocol")
M.hooks = require("sysinit.ai.core.hooks")
M.terminals = require("sysinit.ai.terminals")
M.config = require("sysinit.ai.config")

M.providers = {
  goose = require("sysinit.ai.providers.goose"),
  claude = require("sysinit.ai.providers.claude"),
  cursor = require("sysinit.ai.providers.cursor"),
  opencode = require("sysinit.ai.providers.opencode"),
}

local current_config = nil

function M.setup(user_opts)
  user_opts = user_opts or {}

  current_config = M.config.setup(user_opts)

  -- Validate configuration
  local valid, errors = M.config.validate(current_config)
  if not valid then
    vim.notify("AI configuration errors:\\n" .. table.concat(errors, "\\n"), vim.log.levels.ERROR)
    return false
  end

  -- Setup hooks system
  if current_config.hooks.enabled then
    M.hooks.setup({
      load_settings = current_config.hooks.load_from_settings,
      hooks = current_config.hooks.custom_hooks,
    })
  end

  -- Setup providers
  for name, provider in pairs(M.providers) do
    local provider_config = current_config.providers[name]
    if provider_config and provider_config.enabled then
      provider.setup({
        port = provider_config.port,
        logger = M.logger.new(name),
      })

      -- Auto-start servers if configured
      if provider_config.auto_start then
        M.server.start(name, {
          port = provider_config.port,
          logger = M.logger.new(name .. "_server"),
        })
      end
    end
  end

  -- Setup terminals integration
  if current_config.terminals.enabled then
    M.terminals.setup_blink_source()
  end

  -- Setup file watching for AI changes
  if current_config.file_watching.enabled then
    M._setup_file_watcher()
  end

  -- Schedule cleanup of old sessions
  if current_config.logging.session_retention_days > 0 then
    vim.defer_fn(function()
      M.cleanup(current_config.logging.session_retention_days)
    end, 5000) -- Cleanup after 5 seconds
  end

  return true
end

-- File watcher for AI-generated changes
function M._setup_file_watcher()
  -- Watch for file changes from AI services
  vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost" }, {
    callback = function(ev)
      local file = ev.file or vim.api.nvim_buf_get_name(ev.buf)

      -- Check if file was modified by AI services
      if M._is_ai_modified(file) then
        M._handle_ai_file_change(file)
      end
    end,
  })
end

-- Check if file was modified by AI
function M._is_ai_modified(file)
  -- Check recent logs for file modifications
  for _, provider in pairs(M.providers) do
    if provider.client and provider.client.logger then
      local transcript = provider.client.logger:get_transcript()
      -- Look for recent file modifications in the last 30 seconds
      local cutoff = os.time() - 30
      for _, entry in ipairs(transcript) do
        if entry.created > cutoff and entry.content then
          for _, content in ipairs(entry.content) do
            if
              content.type == "tool_response"
              and content.result
              and type(content.result) == "string"
              and content.result:find(file, 1, true)
            then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

-- Handle AI-generated file changes
function M._handle_ai_file_change(file)
  vim.schedule(function()
    -- Check if buffer exists and is loaded
    local buf = vim.fn.bufnr(file)
    if buf == -1 then
      return
    end

    -- Check if there are unsaved changes
    if vim.api.nvim_buf_get_option(buf, "modified") then
      vim.notify(
        string.format(
          "AI modified %s but buffer has unsaved changes. Open diff to review?",
          vim.fn.fnamemodify(file, ":t")
        ),
        vim.log.levels.WARN
      )

      -- Offer to open diffview
      vim.ui.select({ "Yes", "No", "Reload anyway" }, {
        prompt = "Open diff view to review changes?",
      }, function(choice)
        if choice == "Yes" then
          M._open_diffview(file)
        elseif choice == "Reload anyway" then
          vim.cmd("checktime " .. buf)
        end
      end)
    else
      -- Auto-reload if no unsaved changes
      vim.cmd("checktime " .. buf)
      vim.notify(
        string.format("Reloaded %s (modified by AI)", vim.fn.fnamemodify(file, ":t")),
        vim.log.levels.INFO
      )
    end
  end)
end

-- Open diffview for file
function M._open_diffview(file)
  local diffview_ok, diffview = pcall(require, "diffview")
  if diffview_ok then
    vim.cmd("DiffviewOpen HEAD -- " .. vim.fn.shellescape(file))
  else
    -- Fallback to vimdiff
    local tmp_file = vim.fn.tempname()
    vim.fn.system(
      string.format("git show HEAD:%s > %s", vim.fn.shellescape(file), vim.fn.shellescape(tmp_file))
    )
    vim.cmd(
      string.format("vsplit %s | diffthis | wincmd p | diffthis", vim.fn.shellescape(tmp_file))
    )
  end
end

-- Get status of all AI services
function M.status()
  local status = {
    servers = M.server.list(),
    providers = {},
    sessions = {},
  }

  for name, provider in pairs(M.providers) do
    status.providers[name] = provider.get_status()
  end

  -- Get session information
  for name, _ in pairs(M.providers) do
    local sessions = M.logger.get_sessions(name)
    status.sessions[name] = #sessions
  end

  return status
end

-- Send prompt to specific provider
function M.prompt(provider_name, text, context)
  if M.terminals then
    return M.terminals.send_prompt(provider_name, text, { context = context })
  end

  local provider = M.providers[provider_name]
  if provider then
    return provider.send_prompt(text, context)
  end

  error("Unknown provider: " .. provider_name)
end

-- Cleanup old sessions
function M.cleanup(days)
  M.logger.cleanup_old_sessions(days or 30)
end

-- Export terminals module for compatibility
M.terminals_module = function()
  return M.terminals
end

return M
