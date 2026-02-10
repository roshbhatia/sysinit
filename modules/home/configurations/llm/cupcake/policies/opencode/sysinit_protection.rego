# METADATA
# scope: package
# title: .sysinit Folder Protection
# description: Block git operations on .sysinit/ folders (globally excluded)
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.sysinit_protection

import rego.v1

# Block git add on .sysinit/ files
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git add")
    regex.match(`\.sysinit/`, command)
    
    decision := {
        "rule_id": "GIT_SYSINIT_ADD",
        "reason": "Cannot add .sysinit/ files to git. This directory is globally excluded via .gitexcludes.",
        "severity": "CRITICAL"
    }
}

# Block git commit -a which would stage .sysinit/ files
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git commit")
    regex.match(`git\s+commit.*-a`, command)
    
    decision := {
        "rule_id": "GIT_SYSINIT_COMMIT_ALL",
        "reason": "Using 'git commit -a' may attempt to stage .sysinit/ files which are globally excluded. Consider staging files explicitly instead.",
        "question": "Are you sure there are no .sysinit/ files that would be inadvertently committed?",
        "severity": "MEDIUM"
    }
}

# Block git status --ignored which might show .sysinit/ files
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git status")
    contains(command, "--ignored")
    
    decision := {
        "rule_id": "GIT_STATUS_IGNORED",
        "reason": "Showing ignored files will display .sysinit/ contents. This directory should remain private.",
        "question": "Do you want to see ignored files including .sysinit/?",
        "severity": "LOW"
    }
}

# Block attempts to force-add .sysinit/ files
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git add")
    contains(command, "-f")
    regex.match(`\.sysinit/`, command)
    
    decision := {
        "rule_id": "GIT_SYSINIT_FORCE_ADD",
        "reason": "Cannot force-add .sysinit/ files. This directory must remain excluded from version control.",
        "severity": "CRITICAL"
    }
}

# Block git rm --cached on .sysinit/ (shouldn't be in git anyway)
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "git rm")
    regex.match(`\.sysinit/`, command)
    
    decision := {
        "rule_id": "GIT_SYSINIT_RM",
        "reason": "Attempting to remove .sysinit/ from git. This directory should never be tracked in the first place.",
        "severity": "HIGH"
    }
}
