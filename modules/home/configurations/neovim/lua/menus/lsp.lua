return {
  {
    label = "Code Action (fastaction)",
    key = "a",
    action = function()
      require("fastaction").code_action()
    end,
  },
  {
    label = "Rename Symbol",
    key = "r",
    action = function()
      vim.lsp.buf.rename()
    end,
  },
  {
    label = "Format Document",
    key = "f",
    action = function()
      vim.lsp.buf.format()
    end,
  },
  {
    label = "Hover (pretty_hover)",
    key = "h",
    action = function()
      require("pretty_hover").hover()
    end,
  },
  {
    label = "Go to Definition",
    key = "d",
    action = function()
      vim.lsp.buf.definition()
    end,
  },
  {
    label = "Trouble Diagnostics",
    key = "t",
    action = function()
      vim.cmd("TroubleToggle")
    end,
  },
  {
    label = "Close Menu",
    key = "q",
    action = function()
      require("menu").close()
    end,
  },
}
