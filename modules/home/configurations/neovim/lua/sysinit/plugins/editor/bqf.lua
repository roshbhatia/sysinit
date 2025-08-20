local M = {}

M.plugins = {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    opts = {
      func_map = {
        open = "<CR>",
        openc = "o",
        drop = "O",
        split = "<C-s>",
        vsplit = "<C-v>",
        tabc = "<C-t>",
        tabdrop = "",
        tab = "",
        tabb = "",
        ptogglemode = "z,",
        ptoggleitem = "p",
        ptoggleauto = "P",
        filter = "zn",
        filterr = "zN",
        fzffilter = "zf",
        prevfile = "<C-p>",
        nextfile = "<C-n>",
        prevhist = "<",
        nexthist = ">",
        lastleave = '"',
        stoggleup = "<S-Tab>",
        stoggledown = "<Tab>",
        stogglevm = "<Tab>",
        stogglebuf = "'<Tab>",
        sclear = "z<Tab>",
        pscrollup = "<C-b>",
        pscrolldown = "<C-f>",
        pscrollorig = "zo",
      },
      preview = {
        winblend = 0,
      },
    },
  },
}

if vim then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
      vim.keymap.set("n", "dd", function()
        local qf_idx = vim.fn.line(".")
        local qflist = vim.fn.getqflist()
        table.remove(qflist, qf_idx)
        vim.fn.setqflist({}, "r", { items = qflist })
        local new_count = #qflist
        if new_count == 0 then
          vim.cmd("cclose")
        else
          vim.api.nvim_win_set_cursor(0, { math.min(qf_idx, new_count), 0 })
        end
      end, { buffer = true, desc = "Remove item from quickfix list" })
    end,
  })
end

return M
