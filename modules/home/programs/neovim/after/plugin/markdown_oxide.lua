-- markdown_oxide: only enable if .obsidian folder exists in workspace root
local function has_obsidian_workspace()
  return vim.fn.isdirectory(vim.fn.getcwd() .. "/.obsidian") == 1
end

if has_obsidian_workspace() then
  local capabilities = vim.tbl_deep_extend(
    "force",
    require("blink.cmp").get_lsp_capabilities(),
    {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    }
  )

  vim.lsp.config("markdown_oxide", {
    cmd = { "markdown-oxide" },
    root_markers = { ".obsidian" },
    capabilities = capabilities,
  })
  vim.lsp.enable({ "markdown_oxide" })
end
