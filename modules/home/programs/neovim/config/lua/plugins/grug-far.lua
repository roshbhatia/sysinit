return {
  {
    "MagicDuck/grug-far.nvim",
    event = "VeryLazy",
    opts = {
      showEngineInfo = false,
      normalModeSearch = true,
      windowCreationCommand = "aboveleft vsplit | wincmd H | silent! Neotree close",
      openTargetWindow = {
        preferredLocation = "right",
      },
      searchOnInsertLeave = true,
      resultLocation = {
        showNumberLabel = false,
      },
    },
    keys = {
      {
        "<leader>fG",
        function()
          require("grug-far").toggle_instance({
            instanceName = "far-global",
            staticTitle = "Global Search",
            prefills = { search = vim.fn.expand("<cword>"), filesFilter = "*" },
          })
        end,
        desc = "Grep (alt.)",
        mode = { "n", "v" },
      },
    },
  },
}
