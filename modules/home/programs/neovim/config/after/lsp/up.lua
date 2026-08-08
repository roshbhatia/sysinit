local neoconf = require("neoconf")

local base_config = {
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
    local git_root = vim.fs.root(bufnr, ".git")
    if not git_root then
      return nil
    end

    local crossplane_at_root = vim.fn.filereadable(git_root .. "/crossplane.yaml") == 1
    local crossplane_in_pkg = vim.fn.filereadable(git_root .. "/package/crossplane.yaml") == 1

    if crossplane_at_root or crossplane_in_pkg then
      on_dir(git_root)
    end
  end,
  single_file_support = false,
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and type(result.diagnostics) == "userdata" then
        result.diagnostics = {}
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
    end,
  },
}

return vim.tbl_deep_extend("force", base_config, neoconf.get("up") or {})
