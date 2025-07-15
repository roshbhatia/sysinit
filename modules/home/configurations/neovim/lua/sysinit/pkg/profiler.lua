local M = {}

function M.setup()
	local profile_started = false
	local function start_profile()
		if not profile_started then
			require("plenary.profile").start("profile.log", { flame = true })
			print("Plenary profiling started (post-startup event)")
			profile_started = true
		end
	end

	vim.api.nvim_create_autocmd({
		"InsertEnter", -- Entering insert mode
		"LspAttach", -- LSP attaches to buffer
		"TextChangedI", -- Text changes in insert mode
		"BufEnter", -- Entering a buffer
		"BufWritePost", -- After writing buffer
		"CursorMovedI", -- Cursor moves in insert mode
		"FileType", -- Filetype detected (often triggers Treesitter)
		"DiagnosticChanged", -- Diagnostics update (LSP)
	}, {
		callback = start_profile,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function()
			require("plenary.profile").stop()
			print("Plenary profiling stopped (VimLeavePre)")
		end,
	})
end

return M
