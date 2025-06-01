local M = {}

local function get_listed_buffers()
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			table.insert(buffers, buf)
		end
	end
	return buffers
end

local function buffer_next()
	local buffers = get_listed_buffers()
	local current = vim.api.nvim_get_current_buf()
	for i, buf in ipairs(buffers) do
		if buf == current then
			local next_buf = buffers[i + 1] or buffers[1]
			vim.api.nvim_set_current_buf(next_buf)
			return
		end
	end
end

local function buffer_prev()
	local buffers = get_listed_buffers()
	local current = vim.api.nvim_get_current_buf()
	for i, buf in ipairs(buffers) do
		if buf == current then
			local prev_buf = buffers[i - 1] or buffers[#buffers]
			vim.api.nvim_set_current_buf(prev_buf)
			return
		end
	end
end

function M.setup()
	vim.keymap.set("n", "<leader>x", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent quit!")
	end, {
		noremap = true,
		silent = true,
		desc = "Buffer: Close",
	})

	vim.keymap.set("n", "<leader>s", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
	end, {
		noremap = true,
		silent = true,
		desc = "Buffer: Write",
	})

	vim.keymap.set("n", "<leader>w", function()
		vim.cmd("silent SessionSave")
		vim.cmd("silent write!")
		vim.cmd("silent quit!")
	end, {
		noremap = true,
		silent = true,
		desc = "Buffer: Write and close",
	})

	vim.keymap.set("n", "<leader>bn", buffer_next, {
		noremap = true,
		silent = true,
		desc = "Buffer: Next",
	})

	vim.keymap.set("n", "<leader>bp", buffer_prev, {
		noremap = true,
		silent = true,
		desc = "Buffer: Previous",
	})
end

return M

