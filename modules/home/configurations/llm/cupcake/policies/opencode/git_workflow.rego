# METADATA
# scope: package
# title: Git Workflow Enforcement
# description: Enforce git best practices and workflows
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.git_workflow

import rego.v1

# Block force push to main/master
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git push")
    contains(command, "--force")
    regex.match(`(main|master)`, command)
    
    decision := {
        "rule_id": "GIT_FORCE_PUSH_MAIN",
        "reason": "Force pushing to main/master branch is prohibited. Use a pull request workflow.",
        "severity": "HIGH"
    }
}

# Block bypassing pre-commit hooks
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git commit")
    contains(command, "--no-verify")
    
    decision := {
        "rule_id": "GIT_NO_VERIFY",
        "reason": "Bypassing pre-commit hooks is not allowed. Fix the issues reported by hooks.",
        "severity": "HIGH"
    }
}

# Require descriptive commit messages
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git commit")
    contains(command, "-m")
    
    lazy_messages := ["wip", "fix", "tmp", "test", "asdf", "update", "changes"]
    some lazy in lazy_messages
    contains(lower(command), lazy)
    
    decision := {
        "rule_id": "GIT_LAZY_COMMIT",
        "reason": "Commit message appears non-descriptive. Consider a more meaningful message.",
        "question": "Proceed with this commit message?",
        "severity": "LOW"
    }
}

# Warn before pushing to main
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git push")
    regex.match(`origin[\s/]+(main|master)`, command)
    
    decision := {
        "rule_id": "GIT_PUSH_MAIN",
        "reason": "Pushing directly to main/master. Consider using a feature branch and PR workflow.",
        "question": "Are you sure you want to push to main/master?",
        "severity": "MEDIUM"
    }
}

# Block committing gitignored directories
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git add")
    
    gitignored_dirs := ["openspec/", ".opencode/", ".claude/", ".sysinit/"]
    some dir in gitignored_dirs
    contains(command, dir)
    
    decision := {
        "rule_id": "GIT_IGNORED_DIR",
        "reason": sprintf("Attempting to commit gitignored directory: %s. These directories should not be committed to git.", [dir]),
        "severity": "HIGH"
    }
}
