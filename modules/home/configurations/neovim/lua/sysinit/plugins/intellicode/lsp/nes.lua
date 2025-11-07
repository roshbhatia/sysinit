local json_loader = require("sysinit.utils.json_loader")
local theme_config =
  json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

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

  return string.format("NES: %s [gaa: accept, gad: reject]", suggestion_text)
end

function M.setup_enhanced_display(bufnr)
  local custom_ns = vim.api.nvim_create_namespace("copilotlsp.nes.enhanced")

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      vim.api.nvim_set_hl(
        0,
        "NESAccept",
        { fg = theme_config.colors.semantic.success, bold = true }
      )
      vim.api.nvim_set_hl(0, "NESReject", { fg = theme_config.colors.semantic.error, bold = true })
      vim.api.nvim_set_hl(
        0,
        "NESHint",
        { fg = theme_config.colors.foreground.muted, italic = true }
      )
    end,
    group = vim.api.nvim_create_augroup("NESColors", { clear = true }),
  })

  vim.api.nvim_set_hl(0, "NESAccept", { fg = theme_config.colors.semantic.success, bold = true })
  vim.api.nvim_set_hl(0, "NESReject", { fg = theme_config.colors.semantic.error, bold = true })
  vim.api.nvim_set_hl(0, "NESHint", { fg = theme_config.colors.foreground.muted, italic = true })

  local function enhance_nes_display(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local state = vim.b[buf].nes_state
    if not state then
      return
    end

    local start_line = state.range.start.line
    local line_text = vim.api.nvim_buf_get_lines(buf, start_line, start_line + 1, false)[1] or ""
    local line_length = #line_text

    vim.api.nvim_buf_set_extmark(buf, custom_ns, start_line, line_length, {
      virt_text = {
        { "  ", "Normal" },
        { "gaa", "NESAccept" },
        { ": accept, ", "NESHint" },
        { "gad", "NESReject" },
        { ": reject", "NESHint" },
      },
      virt_text_pos = "eol",
    })
  end

  local function clear_enhanced_display(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.api.nvim_buf_clear_namespace(buf, custom_ns, 0, -1)
  end

  local au = vim.api.nvim_create_augroup("NESDisplay", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(event)
      local buf = event.buf

      local nes_timer = vim.loop.new_timer()
      local function check_nes_state()
        if not vim.api.nvim_buf_is_valid(buf) then
          if nes_timer then
            nes_timer:stop()
            nes_timer:close()
          end
          return
        end

        if vim.b[buf].nes_state and not vim.b[buf].nes_enhanced then
          enhance_nes_display(buf)
          vim.b[buf].nes_enhanced = true
        elseif not vim.b[buf].nes_state and vim.b[buf].nes_enhanced then
          clear_enhanced_display(buf)
          vim.b[buf].nes_enhanced = false
        end
      end

      nes_timer:start(100, 100, vim.schedule_wrap(check_nes_state))

      vim.api.nvim_create_autocmd("BufDelete", {
        buffer = buf,
        callback = function()
          if nes_timer then
            nes_timer:stop()
            nes_timer:close()
          end
        end,
        once = true,
      })
    end,
    group = au,
    buffer = bufnr,
  })
end

function M.setup_keymaps(bufnr)
  vim.keymap.set({ "n", "i" }, "gaa", function()
    M.accept()
  end, { desc = "Accept NES suggestion", buffer = bufnr })

  vim.keymap.set({ "n", "i" }, "gad", function()
    M.reject()
  end, { desc = "Reject NES suggestion", buffer = bufnr })
end

return M
