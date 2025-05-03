if vim.g.vscode then
    require("sysinit.entrypoints.vscode").init()
else
    require("sysinit.entrypoints.neovim").init()
end
