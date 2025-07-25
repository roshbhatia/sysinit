local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>x", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent x")
	end, {
		noremap = true,
		silent = true,
		desc = "Close buffer",
	})

	vim.keymap.set("n", "<leader>w", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
		vim.cmd("silent x")
	end, {
		noremap = true,
		silent = true,
		desc = "Save and close current buffer",
	})

	vim.keymap.set("n", "<leader>s", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
	end, {
		noremap = true,
		silent = true,
		desc = "Save current buffer",
	})

	vim.keymap.set("n", "<leader>bn", function()
		local bufs = vim.tbl_filter(function(buf)
			return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
		end, vim.api.nvim_list_bufs())
		local cur = vim.api.nvim_get_current_buf()
		local idx = nil
		for i, buf in ipairs(bufs) do
			if buf == cur then
				idx = i
				break
			end
		end
		if idx == nil or #bufs < 2 then
			return
		end
		local next = bufs[(idx % #bufs) + 1]
		vim.cmd("silent! b " .. next)
	end, {
		noremap = true,
		silent = true,
		desc = "Next loaded buffer",
	})

	vim.keymap.set("n", "<leader>bp", function()
		local bufs = vim.tbl_filter(function(buf)
			return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
		end, vim.api.nvim_list_bufs())
		local cur = vim.api.nvim_get_current_buf()
		local idx = nil
		for i, buf in ipairs(bufs) do
			if buf == cur then
				idx = i
				break
			end
		end
		if idx == nil or #bufs < 2 then
			return
		end
		local prev = bufs[(idx - 2) % #bufs + 1]
		vim.cmd("silent! b " .. prev)
	end, {
		noremap = true,
		silent = true,
		desc = "Previous loaded buffer",
	})

	vim.keymap.set("n", "<leader>bc", function()
		local current = vim.api.nvim_get_current_buf()
		local buffers = vim.api.nvim_list_bufs()
		for _, buf in ipairs(buffers) do
			if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
				local name = vim.api.nvim_buf_get_name(buf)
				if name == "" or vim.bo[buf].buftype ~= "" then
					vim.api.nvim_buf_delete(buf, { force = false })
				end
			end
		end
		vim.cmd("silent SessionSave")
	end, {
		noremap = true,
		silent = true,
		desc = "Close unlisted buffers",
	})
end

return M

