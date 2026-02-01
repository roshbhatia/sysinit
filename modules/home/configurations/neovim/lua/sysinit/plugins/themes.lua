if not vim.g.nix_managed then
  return {
    {
      "RRethy/base16-nvim",
      config = function()
        vim.cmd.colorscheme("base16-tokyo-night-terminal-light")
      end,
    },
  }
end

return require("sysinit.plugins.ui.theme")
