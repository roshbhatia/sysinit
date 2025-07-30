local M = {}

function M.setup()
  if vim.env.SYSINIT_DEBUG == "1" then
    local snacks_path = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
    vim.opt.rtp:append(snacks_path)
    local snacks_profiler = require("snacks.profiler")
    snacks_profiler.start({})
  end
end

return M
