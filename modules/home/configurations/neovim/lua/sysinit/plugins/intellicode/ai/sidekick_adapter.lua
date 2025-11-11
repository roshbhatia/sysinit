-- Adapter module to provide ai-terminals-like API using sidekick.nvim
local M = {}

-- Track active terminal tools
local active_tools = {
  copilot = false,
  claude = false,
  cursor = false,
  opencode = false,
  goose = false,
}

-- Map tool names to sidekick tool names (in case they differ)
local tool_name_map = {
  copilot = "copilot",
  claude = "claude",
  cursor = "cursor",
  opencode = "opencode",
  goose = "goose",
}

-- Get the sidekick CLI module
local function get_cli()
  local ok, cli = pcall(require, "sidekick.cli")
  if not ok then
    vim.notify("Sidekick CLI not available", vim.log.levels.ERROR)
    return nil
  end
  return cli
end

-- Open a terminal for a specific tool
function M.open(termname)
  local cli = get_cli()
  if not cli then
    return
  end

  local tool_name = tool_name_map[termname] or termname

  -- Use sidekick's tool selection to open the specific tool
  -- If the tool is already active, this will show it
  cli.toggle({ tool = tool_name })
  active_tools[termname] = true
end

-- Toggle a terminal
function M.toggle(termname)
  local cli = get_cli()
  if not cli then
    return
  end

  local tool_name = tool_name_map[termname] or termname
  cli.toggle({ tool = tool_name })
  active_tools[termname] = not active_tools[termname]
end

-- Focus the current terminal
function M.focus()
  local cli = get_cli()
  if not cli then
    return
  end

  -- Sidekick automatically focuses when you interact with it
  -- We can trigger a toggle to ensure focus
  cli.toggle()
end

-- Send text to a terminal
function M.send_term(termname, text, opts)
  opts = opts or {}
  local cli = get_cli()
  if not cli then
    return
  end

  local tool_name = tool_name_map[termname] or termname

  -- Ensure the terminal is open first
  if not active_tools[termname] then
    M.open(termname)
    -- Give it time to open
    vim.defer_fn(function()
      cli.send({ msg = text, tool = tool_name })
    end, 500)
  else
    cli.send({ msg = text, tool = tool_name })
  end
end

-- Get terminal info (compatibility with ai-terminals API)
function M.get_term_info(termname)
  -- Sidekick doesn't expose this directly, so we track it ourselves
  return {
    visible = active_tools[termname] or false,
    focused = active_tools[termname] or false, -- Approximate
  }
end

-- Placeholder functions for removed features
-- These are kept for API compatibility but do nothing
function M.diff_changes()
  vim.notify(
    "Diff viewing after changes is not available with sidekick. Use git diff or :DiffviewOpen instead.",
    vim.log.levels.INFO
  )
end

function M.revert_changes()
  vim.notify(
    "Revert functionality is not available with sidekick. Use undo (u) or git reset instead.",
    vim.log.levels.INFO
  )
end

return M
