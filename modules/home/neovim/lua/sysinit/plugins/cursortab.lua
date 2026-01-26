return {
  {
    "leonardcser/cursortab.nvim",
    event = "VeryLazy",
    build = "cd server && go build",
    config = function()
      require("cursortab").setup({
        log_level = "error",
        provider = {
          type = "autocomplete",
          url = "http://localhost:11434/api",
          model = "llama3.2:3b",
        },
      })
    end,
  },
}
