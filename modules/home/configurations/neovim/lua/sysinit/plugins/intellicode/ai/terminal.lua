local M = {}

local last_prompts = {}
local placeholders = nil -- Lazy-loaded

function M.setup_goose_keymaps()
  vim.api.nvim_create_autocmd("TermEnter", {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local term_name = vim.api.nvim_buf_get_name(buf)

      if term_name:match("goose") then
        vim.keymap.set("t", "<S-CR>", "<C-j>", {
          buffer = buf,
          silent = true,
          desc = "Send Ctrl+J in goose terminal",
        })
      end
    end,
  })
end

function M.setup_global_ctrl_l_keymaps()
  -- Ctrl+L is bound to something else, so we don't set it for AI terminals
  -- Keeping this function for backward compatibility but it does nothing now
end

-- Validate and preview placeholders in the prompt before sending
function M.validate_prompt(text)
  if not placeholders then
    placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
  end

  local errors = {}
  local warnings = {}

  -- Check for ast-grep placeholders that might fail
  for pattern in text:gmatch("@astgrep%-pattern:([^%s]+)") do
    if pattern:match("['\"]") then
      table.insert(warnings, string.format("Pattern contains quotes: %s", pattern))
    end
  end

  for lang, pattern in text:gmatch("@astgrep%-lang:([^:]+):([^%s]+)") do
    local supported_langs = {
      "typescript",
      "javascript",
      "python",
      "go",
      "rust",
      "lua",
      "nix",
      "java",
      "c",
      "cpp",
    }
    if not vim.tbl_contains(supported_langs, lang) then
      table.insert(warnings, string.format("Unsupported language: %s", lang))
    end
  end

  return errors, warnings
end

-- Preview the expanded prompt before sending
function M.preview_prompt(text)
  if not placeholders then
    placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
  end

  -- Create a preview buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}

  table.insert(lines, "=== Original Prompt ===")
  table.insert(lines, "")
  vim.list_extend(lines, vim.split(text, "\n"))
  table.insert(lines, "")
  table.insert(lines, "=== Expanded Preview ===")
  table.insert(lines, "")

  -- Show what placeholders will expand to (without actually running expensive operations)
  local preview_text = text
  for _, ph in ipairs(placeholders.placeholder_descriptions) do
    if text:find(ph.token, 1, true) then
      table.insert(lines, string.format("Found: %s - %s", ph.token, ph.description))
    end
  end

  table.insert(lines, "")
  table.insert(lines, "Press 'y' to confirm and send, 'n' to cancel")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  -- Create floating window
  local width = math.min(100, vim.o.columns - 4)
  local height = math.min(#lines + 2, 30)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Prompt Preview ",
    title_pos = "center",
  })

  -- Return a promise-like interface
  local confirmed = false
  vim.keymap.set("n", "y", function()
    confirmed = true
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "n", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })

  return confirmed
end

function M.ensure_terminal_and_send(termname, text, opts)
  opts = opts or {}

  -- Validate the prompt
  local errors, warnings = M.validate_prompt(text)

  if #warnings > 0 then
    for _, warning in ipairs(warnings) do
      vim.notify("Warning: " .. warning, vim.log.levels.WARN)
    end
  end

  if #errors > 0 then
    for _, error in ipairs(errors) do
      vim.notify("Error: " .. error, vim.log.levels.ERROR)
    end
    return
  end

  last_prompts[termname] = text

  local ai_terminals = require("ai-terminals")
  local term_info = ai_terminals.get_term_info and ai_terminals.get_term_info(termname)

  local function send_to_terminal()
    if opts.preview ~= false then
      -- Show a brief notification about placeholder expansion
      local has_placeholders = text:match("@[a-z%-]+")
      if has_placeholders then
        vim.notify("Expanding placeholders...", vim.log.levels.INFO)
      end
    end

    ai_terminals.send_term(termname, text, { submit = true })
  end

  if not term_info or not term_info.visible then
    ai_terminals.open(termname)
    ai_terminals.focus()
    vim.defer_fn(send_to_terminal, 300)
  else
    ai_terminals.focus()
    vim.defer_fn(send_to_terminal, 300)
  end
end

function M.get_last_prompt(termname)
  return last_prompts[termname]
end

function M.set_last_prompt(termname, prompt)
  last_prompts[termname] = prompt
end

-- Send ast-grep results directly to an AI terminal
function M.send_astgrep_to_terminal(termname, pattern, lang)
  if not placeholders then
    placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
  end

  local placeholder_text
  if lang then
    placeholder_text = string.format("@astgrep-preview-lang:%s:%s", lang, pattern)
  else
    placeholder_text = string.format("@astgrep-preview:%s", pattern)
  end

  M.ensure_terminal_and_send(termname, placeholder_text)
end

return M
