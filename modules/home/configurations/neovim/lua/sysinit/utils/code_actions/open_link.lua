-- Code action to open URLs in browser
local M = {}

function M.generator()
  return {
    fn = function()
      local actions = {}
      local node = vim.treesitter.get_node()
      if not node then
        return actions
      end

      local text = vim.treesitter.get_node_text(node, 0)
      if not text then
        return actions
      end

      local url_pattern = "https?://[%w-_%.%?%.:/%+=&]+"
      local url = text:match(url_pattern)
      if url then
        table.insert(actions, {
          title = "Open link in browser",
          action = function()
            vim.fn.jobstart({ "open", url }, { detach = true })
          end,
        })
      end
      return actions
    end,
  }
end

return M
