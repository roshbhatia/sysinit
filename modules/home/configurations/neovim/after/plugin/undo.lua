vim.keymap.set("n", "u", "g-`[", {
  noremap = true,
  silent = true,
  desc = "Undo previous state",
})

vim.keymap.set("n", "U", "g+`[", {
  noremap = true,
  silent = true,
  desc = "Redo next state",
})
