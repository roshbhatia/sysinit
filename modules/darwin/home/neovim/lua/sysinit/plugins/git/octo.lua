local M = {}

M.plugins = {
	{
		"pwntester/octo.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		-- keys = function()
		--     return {{
		--         "<leader>grc",
		--         "<cmd>Octo repo browser<CR>",
		--         desc = "GitHub: Open repo in browser"
		--     }, {
		--         "<leader>grp",
		--         "<cmd>Octo pr list<CR>",
		--         desc = "GitHub: Open PR list"
		--     }, {
		--         "<leader>gri",
		--         "<cmd>Octo pr create<CR>",
		--         desc = "GitHub: Create PR"
		--     }, {
		--         "<leader>grr",
		--         "<cmd>Octo review start<CR>",
		--         desc = "GitHub: Start PR review"
		--     }, {
		--         "<leader>grs",
		--         "<cmd>Octo review submit<CR>",
		--         desc = "GitHub: Submit PR review"
		--     }, {
		--         "<leader>gro",
		--         "<cmd>Octo pr checkout<CR>",
		--         desc = "GitHub: Checkout PR"
		--     }, {
		--         "<leader>grb",
		--         "<cmd>Octo pr browser<CR>",
		--         desc = "GitHub: View PR in browser"
		--     }, {
		--         "<leader>grf",
		--         "<cmd>Octo repo browser<CR>",
		--         desc = "GitHub: View file in browser"
		--     }}
		-- end
	},
}

return M
