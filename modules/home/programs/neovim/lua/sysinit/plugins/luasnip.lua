return {
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    version = "v2.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
