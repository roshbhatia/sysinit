-- Validation via :make
vim.opt_local.makeprg = "cue vet %"
vim.opt_local.errorformat = [[%m:,%Z    %f:%l:%c]]

Snacks.keymap.set("n", "<localleader>xv", "<cmd>make<cr>", { ft = "cue", desc = "Validate (vet)" })
Snacks.keymap.set("n", "<localleader>xe", "<cmd>!cue eval %<cr>", { ft = "cue", desc = "Evaluate" })
Snacks.keymap.set("n", "<localleader>xj", "<cmd>!cue export % --out json<cr>", { ft = "cue", desc = "Export as JSON" })
Snacks.keymap.set("n", "<localleader>xy", "<cmd>!cue export % --out yaml<cr>", { ft = "cue", desc = "Export as YAML" })
