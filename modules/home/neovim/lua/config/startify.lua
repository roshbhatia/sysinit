-- A function that takes the header lines of Startify and centers them based on the current terminal width.
function center_startify(header_lines)
    local padding = string.rep(' ', math.floor((vim.o.columns - 38) / 2))
    local header = {}
    for i, line in ipairs(header_lines) do
        table.insert(header, padding .. line)
    end
    return header
end

-- Define a function to open NERDTree with the selected repository
function startify_open_nerdtree()
    local selected = vim.fn.input('Choose a repo: ')
    vim.cmd('NERDTree ' .. selected)
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

-- Function to disable code preview
local function disable_code_preview() vim.g.code_preview_enabled = false end

-- Function to enable code preview
local function enable_code_preview() vim.g.code_preview_enabled = true end

-- Modify Startify session to toggle code preview
vim.api.nvim_create_autocmd('User', {
    pattern = 'StartifyBufferOpened',
    callback = function()
        vim.g.code_preview_enabled = false
        require('codewindow').setup({auto_enable = false})
    end
})

vim.api.nvim_create_autocmd('User', {
    pattern = 'StartifyBufferClosed',
    callback = function()
        vim.g.code_preview_enabled = true
        require('codewindow').setup({auto_enable = true})
    end
})

