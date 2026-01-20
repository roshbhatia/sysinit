vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99

-- Comment string for Helm (supports both YAML and Go template comments)
vim.opt_local.commentstring = "{{/* %s */}}"

-- Keymaps
Snacks.keymap.set("n", "<localleader>t", "<cmd>!helm template .<cr>", { ft = "helm", desc = "Template chart" })
Snacks.keymap.set("n", "<localleader>l", "<cmd>!helm lint .<cr>", { ft = "helm", desc = "Lint chart" })

-- Quick navigation between Helm resources (similar to k8s)
Snacks.keymap.set("n", "]k", "/^---\\s*$<cr>:nohl<cr>", { ft = "helm", desc = "Next resource" })
Snacks.keymap.set("n", "[k", "?^---\\s*$<cr>:nohl<cr>", { ft = "helm", desc = "Previous resource" })

-- Insert common Helm template expressions
Snacks.keymap.set("n", "<localleader>v", "i{{ .Values. }}<Esc>", { ft = "helm", desc = "Insert Values reference" })
Snacks.keymap.set("n", "<localleader>r", "i{{ .Release. }}<Esc>", { ft = "helm", desc = "Insert Release reference" })
Snacks.keymap.set("n", "<localleader>c", "i{{ .Chart. }}<Esc>", { ft = "helm", desc = "Insert Chart reference" })
