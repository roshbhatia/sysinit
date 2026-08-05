local function normalize_hex_color(hex)
  local color = hex:lower()

  if #color == 4 then
    local r, g, b = color:sub(2, 2), color:sub(3, 3), color:sub(4, 4)
    return ("#%s%s%s%s%s%s"):format(r, r, g, g, b, b)
  end

  if #color == 5 then
    local r, g, b = color:sub(2, 2), color:sub(3, 3), color:sub(4, 4)
    return ("#%s%s%s%s%s%s"):format(r, r, g, g, b, b)
  end

  if #color == 9 then
    return color:sub(1, 7)
  end

  return color
end

return {
  {
    "nvim-mini/mini.nvim",
    event = { "BufReadPost", "BufNewFile" },
    version = "*",
    config = function()
      local hipatterns = require("mini.hipatterns")

      local function hex_group(_, match)
        local normalized = normalize_hex_color(match)
        if not normalized:match("^#%x%x%x%x%x%x$") then
          return nil
        end
        return hipatterns.compute_hex_color_group(normalized, "bg")
      end

      require("mini.move").setup({
        mappings = {
          left = "<S-h>",
          right = "<S-l>",
          down = "<S-j>",
          up = "<S-k>",
        },
        options = {
          reindent_linewise = true,
        },
      })

      hipatterns.setup({
        highlighters = {
          fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
          hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
          todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
          note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
          hex_color = hipatterns.gen_highlighter.hex_color(),
          hex_color_short = { pattern = "#%x%x%x%f[%X]", group = hex_group },
          hex_color_short_alpha = { pattern = "#%x%x%x%x%f[%X]", group = hex_group },
          hex_color_alpha = { pattern = "#%x%x%x%x%x%x%x%x%f[%X]", group = hex_group },
        },
      })
    end,
  },
}
