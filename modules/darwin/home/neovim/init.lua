if vim.g.vscode then
    require("pkg.entrypoints.vscode").init()
else
    require("pkg.entrypoints.neovim").init()
end
