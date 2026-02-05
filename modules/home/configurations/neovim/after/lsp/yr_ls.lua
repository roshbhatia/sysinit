return {
  cmd = {
    "yr-ls",
  },
  filetypes = {
    "yara",
  },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { ".git" })
    on_dir(root or vim.fs.dirname(fname))
  end,
  single_file_support = true,
}
