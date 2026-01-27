-- Validation via :make
vim.opt_local.makeprg = "cue vet %"
vim.opt_local.errorformat = [[%m:,%Z    %f:%l:%c]]

Snacks.keymap.set("n", "<localleader>v", "<cmd>make<cr>", { ft = "cue", desc = "Validate (vet)" })
Snacks.keymap.set("n", "<localleader>e", "<cmd>!cue eval %<cr>", { ft = "cue", desc = "Evaluate" })
Snacks.keymap.set("n", "<localleader>j", "<cmd>!cue export % --out json<cr>", { ft = "cue", desc = "Export as JSON" })
Snacks.keymap.set("n", "<localleader>y", "<cmd>!cue export % --out yaml<cr>", { ft = "cue", desc = "Export as YAML" })
