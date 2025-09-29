local M = {}

-- Enhanced NES functionality inspired by sidekick.nvim
-- Provides better integration with completion and status line

function M.is_available()
  local buf = vim.api.nvim_get_current_buf()
  return vim.b[buf] and vim.b[buf].nes_state ~= nil
end

function M.accept()
  local buf = vim.api.nvim_get_current_buf()
  if not M.is_available() then
    return false
  end

  local nes_mod = require("copilot-lsp.nes")
  if vim.b[buf].nes_navigated then
    nes_mod.apply_pending_nes(buf)
    M.clear_display(buf)
    vim.b[buf].nes_navigated = false
    vim.b[buf].nes_enhanced = false
    return true
  else
    if nes_mod.walk_cursor_start_edit(buf) then
      vim.b[buf].nes_navigated = true
      return true
    end
  end
  return false
end

function M.reject()
  local buf = vim.api.nvim_get_current_buf()
  if not M.is_available() then
    return false
  end

  local nes_mod = require("copilot-lsp.nes")
  nes_mod.clear()
  M.clear_display(buf)
  vim.b[buf].nes_navigated = false
  vim.b[buf].nes_enhanced = false
  return true
end

function M.clear_display(buf)
  vim.api.nvim_buf_clear_namespace(
    buf,
    vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
    0,
    -1
  )
end

function M.get_status_text()
  if not M.is_available() then
    return ""
  end

  local buf = vim.api.nvim_get_current_buf()
  local state = vim.b[buf].nes_state
  if not state then
    return ""
  end

  local suggestion_text = ""
  if state.edits and #state.edits > 0 then
    local first_edit = state.edits[1]
    if first_edit.newText then
      suggestion_text = first_edit.newText:gsub("\n", " "):gsub("%s+", " ")
      if #suggestion_text > 30 then
        suggestion_text = suggestion_text:sub(1, 27) .. "..."
      end
    end
  end

  return string.format("NES: %s [Tab: accept, Esc: reject]", suggestion_text)
end

function M.setup_global_keymaps()
  -- Tab key handling for NES (when not in completion popup)
  vim.keymap.set({ "n", "i" }, "<Tab>", function()
    -- Check if completion popup is visible
    local cmp = require("blink.cmp")
    if cmp and cmp.is_visible and cmp.is_visible() then
      return false -- Let completion handle it
    end

    -- Check for NES availability
    if M.is_available() then
      return M.accept()
    end

    return false -- Let other handlers take over
  end, { desc = "Accept NES suggestion or fallback to default Tab behavior" })

  -- Esc key handling for NES rejection
  vim.keymap.set({ "n", "i" }, "<Esc>", function()
    if M.is_available() then
      M.reject()
      return true -- Consume the key
    end
    return false -- Let other handlers take over
  end, { desc = "Reject NES suggestion or fallback to default Esc behavior" })
end

return M