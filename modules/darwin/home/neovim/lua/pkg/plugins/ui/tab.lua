local plugin_spec = {}

M.plugins = {{
    "nanozuki/tabby.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    event = "VimEnter",
    config = function()
        -- Always show tabline
        vim.o.showtabline = 2

        -- Add tabpages and globals to session options to preserve tab layout and names
        vim.opt.sessionoptions = vim.opt.sessionoptions + {"tabpages", "globals"}

        local theme = {
            fill = 'TabLineFill',
            head = 'TabLine',
            current_tab = 'TabLineSel',
            tab = 'TabLine',
            win = 'TabLine',
            tail = 'TabLine'
        }

        require('tabby').setup({
            line = function(line)
                return {
                    {{
                        '  ',
                        hl = theme.head
                    }, line.sep('', theme.head, theme.fill)},
                    line.tabs().foreach(function(tab)
                        local hl = tab.is_current() and theme.current_tab or theme.tab
                        return {
                            line.sep('', hl, theme.fill),
                            tab.is_current() and ' ' or '󰆣 ',
                            tab.in_jump_mode() and tab.jump_key() or tab.number(),
                            ' ',
                            tab.name(),
                            tab.close_btn(''),
                            line.sep('', hl, theme.fill),
                            hl = hl,
                            margin = ' '
                        }
                    end),
                    line.spacer(),
                    line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
                        return {
                            line.sep('', theme.win, theme.fill),
                            win.is_current() and ' ' or ' ',
                            win.file_icon(),
                            ' ',
                            win.buf_name(),
                            line.sep('', theme.win, theme.fill),
                            hl = theme.win,
                            margin = ' '
                        }
                    end),
                    {line.sep('', theme.tail, theme.fill), {
                        '  ',
                        hl = theme.tail
                    }},
                    hl = theme.fill
                }
            end,
            option = {
                tab_name = {
                    name_fallback = function(tabid)
                        local wins = vim.api.nvim_tabpage_list_wins(tabid)
                        if #wins == 0 then
                            return "Empty"
                        end

                        local focus_win = vim.api.nvim_tabpage_get_win(tabid)
                        local focus_buf = vim.api.nvim_win_get_buf(focus_win)
                        local buf_name = vim.api.nvim_buf_get_name(focus_buf)

                        if buf_name == "" then
                            return "[No Name]"
                        else
                            return vim.fn.fnamemodify(buf_name, ":t")
                        end
                    end
                },
                buf_name = {
                    mode = 'unique'
                }
            }
        })
    end
}}

return plugin_spec
