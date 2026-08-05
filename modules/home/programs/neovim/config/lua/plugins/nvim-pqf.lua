return {
  {
    "yorickpeterse/nvim-pqf",
    event = "VeryLazy",
    opts = {
      max_filename_length = 40,
      signs = {
        error   = { text = "", hl = "DiagnosticSignError" },
        warning = { text = "", hl = "DiagnosticSignWarn" },
        info    = { text = "", hl = "DiagnosticSignInfo" },
        hint    = { text = "", hl = "DiagnosticSignHint" },
      },
    },
  },
}
