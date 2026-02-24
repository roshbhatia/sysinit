vim.opt_local.foldmethod = "indent"
vim.opt_local.foldlevel = 99

vim.opt_local.commentstring = "{{/* %s */}}"

Snacks.keymap.set("n", "<localleader>xt", "<cmd>!helm template .<cr>", { ft = "helm", desc = "Template chart" })

Snacks.keymap.set("n", "]k", "/^---\\s*$<cr>:nohl<cr>", { ft = "helm", desc = "Next resource" })
Snacks.keymap.set("n", "[k", "?^---\\s*$<cr>:nohl<cr>", { ft = "helm", desc = "Previous resource" })

Snacks.keymap.set("n", "<localleader>xv", "i{{ .Values. }}<Esc>", { ft = "helm", desc = "Insert Values reference" })
Snacks.keymap.set("n", "<localleader>xr", "i{{ .Release. }}<Esc>", { ft = "helm", desc = "Insert Release reference" })
Snacks.keymap.set("n", "<localleader>xc", "i{{ .Chart. }}<Esc>", { ft = "helm", desc = "Insert Chart reference" })
