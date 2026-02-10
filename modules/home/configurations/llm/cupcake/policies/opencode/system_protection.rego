# METADATA
# scope: package
# title: System Protection Policy
# description: Prevent destructive system operations
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.system_protection

import rego.v1

# Block dangerous rm operations
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    # Check for dangerous rm patterns
    dangerous_patterns := [
        "rm -rf /",
        "rm -rf /*",
        "rm -rf ~",
        "rm -rf $HOME",
    ]
    
    some pattern in dangerous_patterns
    contains(command, pattern)
    
    decision := {
        "rule_id": "SYS_DANGEROUS_RM",
        "reason": "Blocked extremely dangerous rm command that could destroy the system",
        "severity": "CRITICAL"
    }
}

# Block system directory modifications
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    protected_dirs := ["/etc", "/bin", "/sbin", "/usr", "/var", "/sys"]
    
    some dir in protected_dirs
    contains(command, dir)
    regex.match(`(rm|mv|chmod|chown).*/` + dir, command)
    
    decision := {
        "rule_id": "SYS_PROTECTED_DIR",
        "reason": concat("", ["Attempted to modify protected system directory: ", dir]),
        "severity": "HIGH"
    }
}

# Warn on sudo usage
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    startswith(trim_space(command), "sudo ")
    
    decision := {
        "rule_id": "SYS_SUDO_WARNING",
        "reason": "Command requires elevated privileges. Ensure you understand what this will do.",
        "question": "Do you want to run this command with sudo?",
        "severity": "MEDIUM"
    }
}
