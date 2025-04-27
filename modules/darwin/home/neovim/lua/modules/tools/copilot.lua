-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/CopilotC-Nvim/CopilotChat.nvim/master/doc/CopilotChat.txt"
local M = {}

M.plugins = {{
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = false,
    dependencies = {"nvim-lua/plenary.nvim", "github/copilot.vim", "zbirenbaum/copilot.lua", "hrsh7th/nvim-cmp",
                    "zbirenbaum/copilot-cmp"},
    config = function()
        require("copilot_cmp").setup({
            event = {"InsertEnter", "LspAttach"},
            fix_pairs = true
        })

        require("copilot").setup({
            suggestion = {
                enabled = true
            },
            panel = {
                enabled = true
            },
            filetypes = {
                ["*"] = true,
                ["help"] = false,
                ["gitcommit"] = false,
                ["gitrebase"] = false,
                ["hgcommit"] = false,
                ["svn"] = false,
                ["cvs"] = false
            }
        })

        -- Enable for specific filetypes
        vim.g.copilot_filetypes = {
            ["*"] = true,
            ["markdown"] = true,
            ["yaml"] = true,
            ["help"] = false,
            ["gitrebase"] = false,
            ["hgcommit"] = false,
            ["svn"] = false,
            ["cvs"] = false
        }

        -- Highlight copilot suggestions with a more subtle color
        vim.api.nvim_create_autocmd("ColorScheme", {
            pattern = "*",
            callback = function()
                vim.api.nvim_set_hl(0, "CopilotSuggestion", {
                    fg = "#888888",
                    ctermfg = 8,
                    force = true
                })
            end
        })
        vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {
            fg = "#888888"
        })

        require("CopilotChat").setup({
            -- Model and agent configuration
            model = "copilot:claude-3.5-sonnet",
            agent = "copilot",

            -- Context and selection settings
            auto_insert_mode = false,

            -- Custom or extended prompts
            system_prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nImplement a new feature based on the context and description below.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring multiple angles and approaches. You MUST break down the solution into clear steps within <step> tags. You SHALL start with a 20-step budget, requesting more for complex problems if needed. You MUST use <count> tags after each step to show the remaining budget. You SHALL stop when reaching 0. You MUST continuously adjust your reasoning based on intermediate results and reflections, adapting your strategy as you progress. You SHALL regularly evaluate progress using <reflection> tags. You MUST be critical and honest about your reasoning process. You SHALL assign a quality score between 0.0 and 1.0 using <reward> tags after each reflection. You MUST use this to guide your approach:\n0.8+: Continue current approach\n0.5-0.7: Consider minor adjustments\nBelow 0.5: Seriously consider backtracking and trying a different approach\nIf unsure or if reward score is low, you SHOULD backtrack and try a different approach, explaining your decision within <thinking> tags. For mathematical problems, you MUST show all work explicitly using LaTeX for formal notation and provide detailed proofs. You SHOULD explore multiple solutions individually if possible, comparing approaches in reflections. You SHALL use thoughts as a scratchpad, writing out all calculations and reasoning explicitly. You MUST synthesize the final answer within <answer> tags, providing a clear, concise summary. You SHALL conclude with a final reflection on the overall solution, discussing effectiveness, challenges, and solutions. You MUST assign a final reward score.",
            prompts = {
                Optimize = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nOptimize the selected code for improved performance and readability.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, analyzing performance bottlenecks and readability issues. You MUST break down the optimization process into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the optimized code and explanation within <answer> tags."
                },
                Tests = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nGenerate comprehensive tests for the selected code.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring various testing approaches and edge cases. You MUST structure the test creation process in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final test suite within <answer> tags."
                },
                Review = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nConduct a thorough code review of the selected code, focusing on security, efficiency, and best practices.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, examining multiple aspects of code quality. You MUST break down the review into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your findings using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final code review within <answer> tags.",
                    system_prompt = 'COPILOT_REVIEW'
                },
                Docs = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nGenerate comprehensive documentation for the selected code, including function descriptions, parameters, return values, and examples.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring how to best document each component. You MUST structure the documentation process within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate the quality of documentation using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final documentation within <answer> tags."
                },
                RefactorCode = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nRefactor the selected code to improve its structure while maintaining functionality.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring refactoring patterns and approaches. You MUST break down the refactoring process into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the refactored code and explanation within <answer> tags."
                },
                Explain = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nExplain the programming concept demonstrated in the selected code in depth, with examples and analogies.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring different ways to explain the concept. You MUST structure your explanation in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate the clarity of your explanation using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final concept explanation within <answer> tags.",
                    system_prompt = 'COPILOT_EXPLAIN'
                },
                Commit = {
                    prompt = 'Write commit message for the change with commitizen convention. Keep the title under 50 characters and wrap message at 72 characters. Format as a gitcommit code block.',
                    context = 'git:staged'
                }
            }
        })
    end
}}

return M
