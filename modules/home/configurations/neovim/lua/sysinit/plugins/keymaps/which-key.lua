local M = {}

local function get_env_bool(key, default)
  local value = vim.fn.getenv(key)
  if value == vim.NIL or value == "" then
    return default
  end
  return value:lower() == "true" or value == "1"
end

M.plugins = {
  {
    "folke/which-key.nvim",
    lazy = false,
    config = function()
      local wk = require("which-key")

      wk.setup({
        preset = "helix",
        icons = {
          mappings = false,
          separator = " ",
        },
        notify = false,
        win = {
          border = "rounded",
          wo = {
            winblend = 0,
          },
        },
        layout = {
          spacing = 6,
          align = "center",
        },
      })

      wk.add({
        {
          "<leader>?",
          group = "Open command palette",
        },
        {
          "<leader>b",
          group = "Buffer",
        },
        {
          "<leader>c",
          group = "Code",
        },
        {
          "<leader>d",
          group = "Debugger",
        },
        {
          "<leader>e",
          group = "Editor",
        },
        {
          "<leader>f",
          group = "Find",
        },
        {
          "<leader>g",
          group = "Git",
        },
        {
          "<leader>m",
          group = "Marks",
        },
        {
          "<leader>n",
          group = "Notifications",
        },
        {
          "<leader>q",
          group = "Qflist/Loclist",
        },
        {
          "<leader>r",
          group = "Refresh",
        },
      })

      if get_env_bool("SYSINIT_AGENTS_ENABLED", true) then
        wk.add({
          {
            "<leader>j",
            group = "Agent",
          },
        })
      end

      if vim.env.SYSINIT_DEBUG == "1" then
        wk.add({
          {
            "<leader>p",
            group = "Profiler",
          },
        })
      end
    end,
  },
}

return M
