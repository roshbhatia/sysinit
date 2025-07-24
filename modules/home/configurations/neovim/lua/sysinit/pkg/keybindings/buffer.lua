local M = {}

function M.setup()
  vim.keymap.set("n", "<C-t>", function()
    require("menu").open("default")
  end, {
    noremap = true,
    silent = true,
    desc = "Open main menu",
  })

  vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
    require('menu.utils').delete_old_menus()
    vim.cmd.exec '"normal! \\<RightMouse>"'
    local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
    local options = vim.bo[buf].ft == "neo-tree" and "neotree" or "default"
    require("menu").open(options, { mouse = true })
  end, {
    noremap = true,
    silent = true,
    desc = "Open menu with mouse",
  })

  -- Existing buffer keymaps below
  vim.keymap.set("n", "<leader>x", function()
    vim.cmd("silent SessionSave")
    vim.cmd("silent x")
  end, {
    noremap = true,
    silent = true,
    desc = "Close buffer",
  })

  vim.keymap.set("n", "<leader>w", function()
    vim.cmd("silent SessionSave")
    vim.cmd("silent write!")
    vim.cmd("silent x")
  end, {
    noremap = true,
    silent = true,
    desc = "Save and close current buffer",
  })

  vim.keymap.set("n", "<leader>s", function()
    vim.cmd("silent SessionSave")
    vim.cmd("silent write!")
  end, {
    noremap = true,
    silent = true,
    desc = "Save current buffer",
  })

  vim.keymap.set("n", "<localleader>s", function()
    vim.cmd("noautocmd write")
  end, {
    noremap = true,
    silent = true,
    desc = "Save without formatting",
  })

  vim.keymap.set("n", "<leader>bn", function()
    local bufs = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
    if #bufs > 1 then
      vim.cmd("bnext")
    end
  end, {
    noremap = true,
    silent = true,
    desc = "Next buffer",
  })

  vim.keymap.set("n", "<leader>bp", function()
    local bufs = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
    if #bufs > 1 then
      vim.cmd("bprevious")
    end
  end, {
    noremap = true,
    silent = true,
    desc = "Previous buffer",
  })

  vim.keymap.set("n", "<leader>bc", function()
    local current = vim.api.nvim_get_current_buf()
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
      if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "" or vim.bo[buf].buftype ~= "" then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end
    vim.cmd("silent SessionSave")
  end, {
    noremap = true,
    silent = true,
    desc = "Close unlisted buffers",
  })
end

return M
