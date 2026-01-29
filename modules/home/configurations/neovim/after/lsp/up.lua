-- Crossplane XPLS language server
-- Activates for YAML files when crossplane.yaml exists anywhere in the repo
return {
  cmd = { "up", "xpls", "serve" },
  filetypes = {
    "yaml",
  },
  root_markers = {
    ".git",
    "crossplane.yaml",
    "package/crossplane.yaml",
  },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local util = require("lspconfig.util")

    -- Find git root first
    local git_root = util.root_pattern(".git")(fname)
    if not git_root then
      return nil
    end

    -- Check if crossplane.yaml exists at root or in package/
    local crossplane_at_root = vim.fn.filereadable(git_root .. "/crossplane.yaml") == 1
    local crossplane_in_pkg = vim.fn.filereadable(git_root .. "/package/crossplane.yaml") == 1

    if crossplane_at_root or crossplane_in_pkg then
      on_dir(git_root)
    end
  end,
  single_file_support = false,
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      -- Fix: up xpls sometimes sends diagnostics = {} (object) instead of [] (array)
      -- Neovim decodes empty JSON object as vim.empty_dict() userdata, causing crash
      if result and type(result.diagnostics) == "userdata" then
        result.diagnostics = {}
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
    end,
  },
}
