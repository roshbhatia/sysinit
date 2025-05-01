if vim.g.vscode then
    require("entrypoints.vscode").init()
else
    require("entrypoints.neovim").init()
end
