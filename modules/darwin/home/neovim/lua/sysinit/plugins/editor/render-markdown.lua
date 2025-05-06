local M = {}

M.plugins = {{
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = true,
    event = "VeryLazy",
    ft = {"markdown", "Avante"},
    opts = {
        file_types = {"markdown", "mermaid"},
        custom_handlers = {
            mermaid = {
                parse = function(ctx)
                    local marks = {}
                    local buffer_name = vim.fn.bufname(ctx.buf):gsub("[^%w]", "_")
                    local base_dir = "/tmp/nvim/render-markdown/" .. buffer_name
                    vim.fn.mkdir(base_dir, "p")
                    for _, node in ipairs(ctx.root:iter_children()) do
                        local start_row, _, end_row, _ = node:range()
                        local content = vim.treesitter.query.get_node_text(node, ctx.buf)
                        local hash = vim.fn.sha256(content)
                        local output_file = string.format("%s/%s.svg", base_dir, hash)
                        marks[#marks + 1] = {
                            conceal = true,
                            start_row = start_row,
                            start_col = 0,
                            opts = {
                                end_row = end_row,
                                virt_text = {{"Rendering Mermaid Diagram...", "Comment"}},
                                virt_text_pos = "eol"
                            }
                        }
                        vim.fn.system({"mmdc", "-i", "/tmp/diagram.mmd", "-o", output_file})
                    end
                    return marks
                end
            }
        }
    }
}}

return M
