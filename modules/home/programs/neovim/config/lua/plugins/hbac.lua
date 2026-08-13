return {
  {
    -- A review across several repositories opens a file per entry and closes none of
    -- them. This closes the oldest buffer nobody edited once the count passes the
    -- threshold, so stepping through a hundred-file diff does not leave a hundred buffers.
    "axkirillov/hbac.nvim",
    event = "VeryLazy",
    config = function()
      require("hbac").setup({
        autoclose = true,
        -- A buffer becomes pinned by being edited, which is the right rule here: a file
        -- opened to read is disposable, a file opened to change is not.
        autopin = true,
        autopin_events = { "InsertEnter", "BufModifiedSet" },
        threshold = 12,
        -- Pinned buffers are the ones being worked on, so they do not push the disposable
        -- ones out of the count.
        count_pinned = false,
        -- Never close a buffer that is on screen: a diff shows two of them at once, and
        -- closing the one being read is worse than holding one buffer too many.
        close_buffers_with_windows = false,
      })
    end,
    keys = {
      {
        "<leader>bp",
        function()
          require("hbac").toggle_pin()
        end,
        desc = "Pin this buffer against auto-close",
        mode = "n",
      },
    },
  },
}
