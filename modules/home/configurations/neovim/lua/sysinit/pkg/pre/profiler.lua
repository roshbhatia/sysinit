local M = {}

function M.setup()
	if vim.env.PROF == "1" then
		local snacks_path = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
		vim.opt.rtp:append(snacks_path)
		local snacks_profiler = require("snacks.profiler")
		snacks_profiler.startup({
			on_stop = {
				pick = false,
			},
			startup = {
				event = "BufWritePost",
				after = true,
				pattern = nil,
				pick = false,
			},
		})
	end
end

return M
