-- A function that takes the header lines of Startify and centers them based on the current terminal width.
function center_startify(header_lines)
    local padding = string.rep(' ', math.floor((vim.o.columns - 38) / 2))
    local header = {}
    for i, line in ipairs(header_lines) do
        table.insert(header, padding .. line)
    end
    return header
end

-- A function that takes a command and returns a function that can be used as the type for a Startify list.
-- The returned function will run the given command and return a table of file paths to display in Startify.
function command_to_startify_table(command)
    return function()
        local cmd_output = vim.fn.systemlist(command .. ' 2>/dev/null')
        local files = vim.tbl_map(function(v)
            local path = string.gsub(v, os.getenv('HOME'), '~')
            return {line = '  ' .. path, path = v}
        end, cmd_output)
        return files
    end
end

-- Set the Startify custom header.
vim.g.startify_custom_header = center_startify({
    '⠀⠀⠀⠀⠀⠐⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠈⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⣈⣼⣄⣠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠉⠑⢷⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⣼⣐⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠘⡚⢧⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⢃⢿⡇⠀⠀⡾⡀⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠸⣇⠀⠀⠡⣰⠀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠇⣿⠀⢠⣄⢿⠇⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⢸⡇⠜⣭⢸⡀⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⠀⣼⠀⡙⣿⣿⠰⢫⠁⣇⠀⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⢰⣽⠱⡈⠋⠋⣤⡤⠳⠉⡆⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠀⠀⡜⠡⠊⠑⠄⣠⣿⠃⠀⣣⠃⠀⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⠀⠐⣼⡠⠥⠊⡂⣼⢀⣤⠠⡲⢂⡌⡄⠀⠀⠀⠀⠀',
    '⠀⠀⠀⠀⣀⠝⡛⢁⡴⢉⠗⠛⢰⣶⣯⢠⠺⠀⠈⢥⠰⡀⠀⠀',
    '⠀⣠⣴⢿⣿⡟⠷⠶⣶⣵⣲⡀⣨⣿⣆⡬⠖⢛⣶⣼⡗⠈⠢⠀',
    '⢰⣹⠭⠽⢧⠅⢂⣳⠛⢿⡽⣿⢿⡿⢟⣟⡻⢾⣿⣿⡤⢴⣶⡃'
})

-- Set the Startify list entries
vim.g.startify_lists = {
    {type = 'dir', header = {'   Current Directory:'}, path = {vim.fn.getcwd()}},
    {type = 'sessions', header = {'   Sessions'}},
    {type = 'bookmarks', header = {'   Bookmarks'}},
    {type = 'commands', header = {'   Commands'}}, {
        type = command_to_startify_table('find ~/github/*/* -maxdepth 0 -type d'),
        header = {'   Repositories'}
    }
}

-- Enable Startify session autoload.
vim.g.startify_session_autoload = 1

-- Modify Startify session to toggle code preview
vim.api.nvim_create_autocmd('User', {
    pattern = 'StartifyBufferOpened',
    callback = function()
        vim.g.code_preview_enabled = false
        local ok, codewindow = pcall(require, 'codewindow')
        if ok then
            codewindow.setup({auto_enable = false})
        end
    end
})

vim.api.nvim_create_autocmd('User', {
    pattern = 'StartifyBufferClosed',
    callback = function()
        vim.g.code_preview_enabled = true
        local ok, codewindow = pcall(require, 'codewindow')
        if ok then
            codewindow.setup({auto_enable = true})
        end
    end
})

