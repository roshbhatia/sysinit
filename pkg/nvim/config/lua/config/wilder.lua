local wilder = require('wilder')
wilder.setup({modes = {':', '/', '?'}})

wilder.set_option('pipeline', {
    wilder.branch(wilder.cmdline_pipeline(), wilder.search_pipeline())
})

wilder.set_option('renderer', wilder.popupmenu_renderer({
    -- highlighter applies highlighting to the candidates
    highlighter = wilder.basic_highlighter()
}))
