local M = {}

function M.setup(client, bufnr)
  local au = vim.api.nvim_create_augroup("copilotlsp.init", { clear = true })
  local nes = require("copilot-lsp.nes")
  local debounced_request =
    require("copilot-lsp.util").debounce(nes.request_nes, vim.g.copilot_nes_debounce or 500)

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    callback = function()
      debounced_request(client)
    end,
    group = au,
    buffer = bufnr,
  })

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

  M.setup_nes_display(bufnr, au)
  M.setup_nes_keymaps(bufnr)
end

function M.setup_nes_display(bufnr, au)
  local custom_ns = vim.api.nvim_create_namespace("copilotlsp.nes.enhanced")

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
        { "gsa", "DiagnosticHint" },
        { ": accept, ", "Comment" },
        { "gsr", "DiagnosticHint" },
        { ": reject", "Comment" },
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

function M.setup_nes_keymaps(bufnr)
  vim.keymap.set({ "n", "i" }, "gsa", function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.b[buf].nes_state then
      local nes_mod = require("copilot-lsp.nes")
      if vim.b[buf].nes_navigated then
        nes_mod.apply_pending_nes(buf)
        vim.api.nvim_buf_clear_namespace(
          buf,
          vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
          0,
          -1
        )
        vim.b[buf].nes_navigated = false
        vim.b[buf].nes_enhanced = false
      else
        if nes_mod.walk_cursor_start_edit(buf) then
          vim.b[buf].nes_navigated = true
        end
      end
    end
  end, { desc = "Navigate to/Accept NES suggestion", buffer = bufnr })

  vim.keymap.set({ "n", "i" }, "gsr", function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.b[buf].nes_state then
      local nes_mod = require("copilot-lsp.nes")
      nes_mod.clear()
      vim.api.nvim_buf_clear_namespace(
        buf,
        vim.api.nvim_create_namespace("copilotlsp.nes.enhanced"),
        0,
        -1
      )
      vim.b[buf].nes_navigated = false
      vim.b[buf].nes_enhanced = false
    end
  end, { desc = "Reject NES", buffer = bufnr })
end

return M