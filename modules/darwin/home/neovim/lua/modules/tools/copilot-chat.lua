-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/CopilotC-Nvim/CopilotChat.nvim/master/doc/CopilotChat.txt"
local M = {}

M.plugins = {{
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = true,
    cmd = {"CopilotChat", "CopilotChatOpen", "CopilotChatToggle", "CopilotChatClose", "CopilotChatReset",
           "CopilotChatExplain", "CopilotChatReview", "CopilotChatFix", "CopilotChatOptimize", "CopilotChatDocs",
           "CopilotChatTests", "CopilotChatCommit"},
    dependencies = {"nvim-lua/plenary.nvim", "github/copilot.vim"},
    config = function()
        local chat = require("CopilotChat")
        local wk = require("which-key")

        chat.setup({
            -- Model and agent configuration
            model = "gpt-4o", -- Using the latest model for better results
            agent = "none", -- Default agent

            -- User interface configuration
            window = {
                layout = "float",
                width = 0.8,
                height = 0.7,
                border = "rounded",
                title = "Copilot Chat"
            },

            -- Context and selection settings
            highlight_selection = true,
            auto_follow_cursor = true,
            auto_insert_mode = true,

            -- Input/output behavior
            show_help = true,
            clear_chat_on_new_prompt = false,

            -- Custom or extended prompts
            prompts = {
                ImplementFeature = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nImplement a new feature based on the context and description below.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring multiple angles and approaches. You MUST break down the solution into clear steps within <step> tags. You SHALL start with a 20-step budget, requesting more for complex problems if needed. You MUST use <count> tags after each step to show the remaining budget. You SHALL stop when reaching 0. You MUST continuously adjust your reasoning based on intermediate results and reflections, adapting your strategy as you progress. You SHALL regularly evaluate progress using <reflection> tags. You MUST be critical and honest about your reasoning process. You SHALL assign a quality score between 0.0 and 1.0 using <reward> tags after each reflection. You MUST use this to guide your approach:\n0.8+: Continue current approach\n0.5-0.7: Consider minor adjustments\nBelow 0.5: Seriously consider backtracking and trying a different approach\nIf unsure or if reward score is low, you SHOULD backtrack and try a different approach, explaining your decision within <thinking> tags. For mathematical problems, you MUST show all work explicitly using LaTeX for formal notation and provide detailed proofs. You SHOULD explore multiple solutions individually if possible, comparing approaches in reflections. You SHALL use thoughts as a scratchpad, writing out all calculations and reasoning explicitly. You MUST synthesize the final answer within <answer> tags, providing a clear, concise summary. You SHALL conclude with a final reflection on the overall solution, discussing effectiveness, challenges, and solutions. You MUST assign a final reward score.",
                    context = "buffer"
                },
                DebugThis = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nDebug the selected code and provide a detailed explanation of the problem and solution.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring multiple angles and approaches. You MUST break down the debugging process into clear steps within <step> tags. You SHALL start with a 20-step budget. You MUST use <count> tags after each step. You SHALL continuously adjust your reasoning based on intermediate results and reflections. You MUST regularly evaluate progress using <reflection> tags and assign a quality score between 0.0 and 1.0 using <reward> tags. You MUST synthesize the final solution within <answer> tags.",
                    context = "buffer"
                },
                ExplainInSimple = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nExplain the selected code in simple terms as if teaching to a beginner.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring how to break down complex concepts. You MUST structure the explanation in clear steps within <step> tags. You SHALL use <reflection> tags to evaluate the clarity of your explanation, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final beginner-friendly explanation within <answer> tags.",
                    context = "buffer"
                },
                OptimizeCode = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nOptimize the selected code for improved performance and readability.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, analyzing performance bottlenecks and readability issues. You MUST break down the optimization process into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the optimized code and explanation within <answer> tags.",
                    context = "buffer"
                },
                TestGenerator = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nGenerate comprehensive tests for the selected code.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring various testing approaches and edge cases. You MUST structure the test creation process in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final test suite within <answer> tags.",
                    context = "buffer"
                },
                CodeReview = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nConduct a thorough code review of the selected code, focusing on security, efficiency, and best practices.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, examining multiple aspects of code quality. You MUST break down the review into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your findings using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final code review within <answer> tags.",
                    context = "buffer"
                },
                DocumentThis = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nGenerate comprehensive documentation for the selected code, including function descriptions, parameters, return values, and examples.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring how to best document each component. You MUST structure the documentation process within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate the quality of documentation using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final documentation within <answer> tags.",
                    context = "buffer"
                },
                RefactorCode = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nRefactor the selected code to improve its structure while maintaining functionality.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring refactoring patterns and approaches. You MUST break down the refactoring process into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate progress using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the refactored code and explanation within <answer> tags.",
                    context = "buffer"
                },
                AlgorithmAnalysis = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nAnalyze the time and space complexity of the selected algorithm and suggest potential improvements.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring the algorithm's behavior across different inputs. You MUST break down the analysis into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your analysis using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final analysis and recommendations within <answer> tags.",
                    context = "buffer"
                },
                DesignPattern = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nIdentify applicable design patterns for the selected code and show how to implement them.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring various design patterns and their applicability. You MUST structure the pattern implementation process within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your approach using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final design pattern recommendations and implementations within <answer> tags.",
                    context = "buffer"
                },
                APIDesign = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nDesign a clean and intuitive API based on the selected code or requirements.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring multiple API design approaches. You MUST structure the design process in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your design using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final API design specification within <answer> tags.",
                    context = "buffer"
                },
                ExplainConcept = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nExplain the programming concept demonstrated in the selected code in depth, with examples and analogies.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring different ways to explain the concept. You MUST structure your explanation in clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate the clarity of your explanation using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final concept explanation within <answer> tags.",
                    context = "buffer"
                },
                SecurityAudit = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nConduct a security audit of the selected code, identifying vulnerabilities and suggesting fixes.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring various security perspectives. You MUST break down the audit into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST regularly evaluate your findings using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final security audit report within <answer> tags.",
                    context = "buffer"
                },
                MathSolution = {
                    prompt = "The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\", \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\nSolve the selected mathematical problem with detailed steps and explanations.\n\nYou MUST begin by enclosing all thoughts within <thinking> tags, exploring multiple solution approaches. You MUST break down the solution into clear steps within <step> tags. You SHALL use <count> tags to track your 20-step budget. You MUST use LaTeX for formal notation and provide detailed proofs. You SHALL regularly evaluate your solution using <reflection> tags, assigning a quality score between 0.0 and 1.0 using <reward> tags. You MUST provide the final solution within <answer> tags.",
                    context = "buffer"
                }
            }
        })
    end
}}

return M
