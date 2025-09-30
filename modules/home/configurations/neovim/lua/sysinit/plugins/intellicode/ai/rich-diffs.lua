local M = {}
local terminal = require("sysinit.plugins.intellicode.ai.terminal")
local input = require("sysinit.plugins.intellicode.ai.input")

-- Rich diff state management
local diff_state = {
  current_diff = nil,
  current_hunk = 1,
  total_hunks = 0,
  diff_buf = nil,
  diff_win = nil,
}

-- Diff parsing utilities
function M.parse_git_diff(diff_output)
  if not diff_output or diff_output == "" then
    return nil
  end

  local hunks = {}
  local current_hunk = nil
  local lines = vim.split(diff_output, "\n")
  local file_info = {}
  
  for i, line in ipairs(lines) do
    -- Parse file headers
    if line:match("^diff --git") then
      local old_file = line:match("^diff --git a/(.+) b/")
      local new_file = line:match("^diff --git a/.+ b/(.+)")
      file_info = {
        old_file = old_file,
        new_file = new_file,
        changes = {}
      }
    elseif line:match("^index") then
      -- Skip index line
    elseif line:match("^---") then
      -- Skip old file marker
    elseif line:match("^%+%+%+") then
      -- Skip new file marker
    elseif line:match("^@@") then
      -- Parse hunk header
      if current_hunk then
        table.insert(hunks, current_hunk)
      end
      
      local old_start, old_count = line:match("^@@ %-(%d+),?(%d*) %+")
      local new_start, new_count = line:match("^@@ %-%d+,?%d* %+(%d+),?(%d*)")
      
      current_hunk = {
        old_start = tonumber(old_start),
        old_count = tonumber(old_count) or 1,
        new_start = tonumber(new_start),
        new_count = tonumber(new_count) or 1,
        lines = {},
        file_info = file_info
      }
    elseif current_hunk then
      -- Parse hunk lines
      local change_type = "context"
      local content = line
      
      if line:match("^%+") then
        change_type = "addition"
        content = line:sub(2)
      elseif line:match("^%-") then
        change_type = "deletion"
        content = line:sub(2)
      end
      
      table.insert(current_hunk.lines, {
        type = change_type,
        content = content,
        line_number = i
      })
    end
  end
  
  if current_hunk then
    table.insert(hunks, current_hunk)
  end
  
  return {
    hunks = hunks,
    file_info = file_info,
    stats = M.calculate_diff_stats(hunks)
  }
end

function M.calculate_diff_stats(hunks)
  local additions = 0
  local deletions = 0
  
  for _, hunk in ipairs(hunks) do
    for _, line in ipairs(hunk.lines) do
      if line.type == "addition" then
        additions = additions + 1
      elseif line.type == "deletion" then
        deletions = deletions + 1
      end
    end
  end
  
  return {
    additions = additions,
    deletions = deletions,
    net_change = additions - deletions
  }
end

-- Rich diff UI
function M.create_rich_diff_window(diff_data, agent_termname, agent_icon)
  if diff_state.diff_win and vim.api.nvim_win_is_valid(diff_state.diff_win) then
    vim.api.nvim_win_close(diff_state.diff_win, true)
  end
  
  -- Create buffer for rich diff
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  
  -- Prepare diff content with rich formatting
  local lines = {}
  local stats = diff_data.stats
  
  -- Add header
  table.insert(lines, "┌─ Rich Diff Analysis ──────────────────────────────")
  table.insert(lines, string.format("│ File: %s", diff_data.file_info.new_file or "Unknown"))
  table.insert(lines, string.format("│ Changes: +%d -%d (net: %+d)", stats.additions, stats.deletions, stats.net_change))
  table.insert(lines, string.format("│ Hunks: %d", #diff_data.hunks))
  table.insert(lines, "├─────────────────────────────────────────────────")
  
  -- Add hunks with rich formatting
  for hunk_idx, hunk in ipairs(diff_data.hunks) do
    table.insert(lines, string.format("│ Hunk %d/%d (lines %d-%d → %d-%d)", 
      hunk_idx, #diff_data.hunks, 
      hunk.old_start, hunk.old_start + hunk.old_count - 1,
      hunk.new_start, hunk.new_start + hunk.new_count - 1))
    
    for _, line in ipairs(hunk.lines) do
      local prefix = "│ "
      if line.type == "addition" then
        prefix = "│+"
      elseif line.type == "deletion" then
        prefix = "│-"
      end
      table.insert(lines, prefix .. line.content)
    end
    
    if hunk_idx < #diff_data.hunks then
      table.insert(lines, "├─────────────────────────────────────────────────")
    end
  end
  
  table.insert(lines, "└─────────────────────────────────────────────────")
  table.insert(lines, "")
  table.insert(lines, "Actions:")
  table.insert(lines, "  <Enter> - Analyze with " .. (agent_termname or "AI"))
  table.insert(lines, "  <Esc>   - Close")
  table.insert(lines, "  a       - Apply changes")
  table.insert(lines, "  r       - Revert changes")
  table.insert(lines, "  s       - Stage hunks")
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set syntax highlighting
  vim.api.nvim_buf_set_option(buf, "syntax", "diff")
  
  -- Create floating window
  local width = math.min(120, vim.o.columns - 4)
  local height = math.min(40, vim.o.lines - 4)
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    border = "rounded",
    title = "Rich Diff: " .. (agent_termname or "AI Analysis"),
    title_pos = "center",
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  
  -- Set up keymaps
  vim.api.nvim_buf_set_keymap(buf, "n", "<Enter>", "", {
    callback = function()
      M.analyze_diff_with_ai(diff_data, agent_termname, agent_icon)
    end,
    desc = "Analyze diff with AI"
  })
  
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    desc = "Close rich diff"
  })
  
  vim.api.nvim_buf_set_keymap(buf, "n", "a", "", {
    callback = function()
      M.apply_diff_changes(diff_data)
    end,
    desc = "Apply changes"
  })
  
  vim.api.nvim_buf_set_keymap(buf, "n", "r", "", {
    callback = function()
      M.revert_diff_changes(diff_data)
    end,
    desc = "Revert changes"
  })
  
  vim.api.nvim_buf_set_keymap(buf, "n", "s", "", {
    callback = function()
      M.stage_diff_hunks(diff_data)
    end,
    desc = "Stage hunks"
  })
  
  -- Store state
  diff_state.current_diff = diff_data
  diff_state.diff_buf = buf
  diff_state.diff_win = win
  diff_state.total_hunks = #diff_data.hunks
  
  return win
end

-- AI Integration
function M.analyze_diff_with_ai(diff_data, agent_termname, agent_icon)
  local prompt = "Analyze this git diff and provide insights:\n\n"
  
  -- Add diff content to prompt
  for _, hunk in ipairs(diff_data.hunks) do
    prompt = prompt .. string.format("Hunk %d (lines %d-%d → %d-%d):\n", 
      hunk_idx, hunk.old_start, hunk.old_start + hunk.old_count - 1,
      hunk.new_start, hunk.new_start + hunk.new_count - 1)
    
    for _, line in ipairs(hunk.lines) do
      if line.type == "addition" then
        prompt = prompt .. "+" .. line.content .. "\n"
      elseif line.type == "deletion" then
        prompt = prompt .. "-" .. line.content .. "\n"
      else
        prompt = prompt .. " " .. line.content .. "\n"
      end
    end
    prompt = prompt .. "\n"
  end
  
  prompt = prompt .. "\nPlease provide:\n"
  prompt = prompt .. "1. A summary of the changes\n"
  prompt = prompt .. "2. Potential issues or improvements\n"
  prompt = prompt .. "3. Suggestions for the code\n"
  
  -- Send to AI terminal
  terminal.ensure_terminal_and_send(agent_termname, prompt)
  
  -- Close rich diff window
  if diff_state.diff_win and vim.api.nvim_win_is_valid(diff_state.diff_win) then
    vim.api.nvim_win_close(diff_state.diff_win, true)
  end
end

function M.generate_commit_message(diff_data, agent_termname, agent_icon)
  local prompt = "Generate a concise commit message for these changes:\n\n"
  
  -- Add summary of changes
  local stats = diff_data.stats
  prompt = prompt .. string.format("Changes: +%d -%d lines in %s\n\n", 
    stats.additions, stats.deletions, diff_data.file_info.new_file or "file")
  
  -- Add key changes
  for _, hunk in ipairs(diff_data.hunks) do
    local additions = 0
    local deletions = 0
    for _, line in ipairs(hunk.lines) do
      if line.type == "addition" then additions = additions + 1 end
      if line.type == "deletion" then deletions = deletions + 1 end
    end
    
    if additions > 0 or deletions > 0 then
      prompt = prompt .. string.format("Hunk %d: +%d -%d lines\n", hunk_idx, additions, deletions)
    end
  end
  
  prompt = prompt .. "\nGenerate a commit message following conventional commit format."
  
  terminal.ensure_terminal_and_send(agent_termname, prompt)
end

-- Diff Actions
function M.apply_diff_changes(diff_data)
  -- This would implement applying specific hunks
  vim.notify("Apply changes functionality - to be implemented", vim.log.levels.INFO)
end

function M.revert_diff_changes(diff_data)
  -- This would implement reverting specific changes
  vim.notify("Revert changes functionality - to be implemented", vim.log.levels.INFO)
end

function M.stage_diff_hunks(diff_data)
  -- This would implement staging specific hunks
  vim.notify("Stage hunks functionality - to be implemented", vim.log.levels.INFO)
end

-- Main interface functions
function M.show_rich_diff(filepath, agent_termname, agent_icon)
  local cmd = string.format("git diff %s", vim.fn.shellescape(filepath))
  local output = vim.fn.system(cmd)
  
  if output == "" then
    vim.notify("No git diff available for " .. filepath, vim.log.levels.WARN)
    return
  end
  
  local diff_data = M.parse_git_diff(output)
  if not diff_data then
    vim.notify("Failed to parse git diff", vim.log.levels.ERROR)
    return
  end
  
  M.create_rich_diff_window(diff_data, agent_termname, agent_icon)
end

function M.show_staged_diff(agent_termname, agent_icon)
  local cmd = "git diff --cached"
  local output = vim.fn.system(cmd)
  
  if output == "" then
    vim.notify("No staged changes available", vim.log.levels.WARN)
    return
  end
  
  local diff_data = M.parse_git_diff(output)
  if not diff_data then
    vim.notify("Failed to parse staged diff", vim.log.levels.ERROR)
    return
  end
  
  M.create_rich_diff_window(diff_data, agent_termname, agent_icon)
end

function M.show_working_diff(agent_termname, agent_icon)
  local cmd = "git diff"
  local output = vim.fn.system(cmd)
  
  if output == "" then
    vim.notify("No working directory changes available", vim.log.levels.WARN)
    return
  end
  
  local diff_data = M.parse_git_diff(output)
  if not diff_data then
    vim.notify("Failed to parse working diff", vim.log.levels.ERROR)
    return
  end
  
  M.create_rich_diff_window(diff_data, agent_termname, agent_icon)
end

return M