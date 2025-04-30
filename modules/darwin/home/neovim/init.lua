if vim.g.vscode then
    require("init-vscode").init()
else
    require("init-neovim").init()
end
