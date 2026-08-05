return {
  {
    "jake-stewart/auto-cmdheight.nvim",
    lazy = false,
    opts = {
      -- max cmdheight before displaying hit enter prompt.
      max_lines = 0,

      -- number of seconds until the cmdheight can restore.
      duration = 0,

      -- whether key press is required to restore cmdheight.
      remove_on_key = false,

      -- always clear the cmdline after duration and key press so stale
      -- message text doesn't linger after cmdheight collapses back to 0.
      clear_always = true,
    },
  },
}
