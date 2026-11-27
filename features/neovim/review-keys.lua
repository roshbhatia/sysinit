local keys = require("reviewr.keymaps")

local function review_key(key)
  if key == "[c" or key == "]c" then
    return key
  end
  return "<LocalLeader>" .. key
end

keys.set_defaults(vim.tbl_map(review_key, keys.defaults))

local function label(key)
  return review_key(key):gsub("^<LocalLeader>", function()
    return vim.g.maplocalleader or "\\"
  end)
end

keys.legend = vim.tbl_map(function(row)
  return { label(row[1]), row[2] }
end, keys.legend)

require("reviewr.ui").hint = function(count)
  local help = label("?") .. "  all keys"
  if (count or 0) == 0 then
    return label("c") .. "  comment on this line    " .. help
  end
  return label("s") .. "  send to agent    " .. label("y") .. "  copy    " .. help
end
