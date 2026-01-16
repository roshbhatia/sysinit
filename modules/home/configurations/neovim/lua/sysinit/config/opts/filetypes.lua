local M = {}

function M.setup()
  vim.filetype.add({
    extension = {
      h = "c",
      -- I'm usually dealing with go templates that are helm
      tmpl = "helm",
    },
  })
end

return M
