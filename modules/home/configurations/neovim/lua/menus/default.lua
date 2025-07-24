return {
  {
    label = "Split Right",
    key = "l",
    action = function()
      vim.cmd("vsplit")
    end,
  },
  {
    label = "Split Below",
    key = "j",
    action = function()
      vim.cmd("split")
    end,
  },
  {
    label = "Buffers",
    key = "b",
    action = function()
      vim.cmd("Telescope buffers")
    end,
  },
  {
    label = "Files",
    key = "f",
    action = function()
      vim.cmd("Telescope find_files")
    end,
  },
  {
    label = "NeoTree",
    key = "n",
    action = function()
      vim.cmd("Neotree toggle")
    end,
  },
  {
    label = "LSP Actions",
    key = "a",
    action = function()
      require("menu").open("lsp")
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
