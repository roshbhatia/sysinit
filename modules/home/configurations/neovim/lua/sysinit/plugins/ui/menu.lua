local M = {}

M.plugins = {
  {
    "nvzone/menu",
    event = "VeryLazy",
    dependencies = { "nvzone/volt" },
    config = function()
      vim.keymap.set("n", "<C-t>", function()
        require("menu").open("default")
      end, { noremap = true, silent = true })

      vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
        require("menu.utils").delete_old_menus()

        vim.cmd.exec('"normal! \\<RightMouse>"')

        -- clicked buf
        local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
        local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

        require("menu").open(options, { mouse = true })
      end, { noremap = true, silent = true })
    end,
  },
}

-- Menu definitions
local menus = {}

menus.default = {
  {
    name = "Format Buffer",
    cmd = function()
      local ok, conform = pcall(require, "conform")

      if ok then
        conform.format({ lsp_fallback = true })
      else
        vim.lsp.buf.format()
      end
    end,
    rtxt = "<leader>fm",
  },

  {
    name = "Code Actions",
    cmd = vim.lsp.buf.code_action,
    rtxt = "<leader>ca",
  },

  { name = "separator" },

  {
    name = "LSP Actions",
    hl = "Exblue",
    items = "lsp",
  },

  {
    name = "Copy Content",
    cmd = "%y+",
    rtxt = "<C-c>",
  },

  {
    name = "Delete Content",
    cmd = "%d",
    rtxt = "dc",
  },
}

-- Register menus globally
vim.g.menu_definitions = menus

return M
