# METADATA
# scope: package
# title: File Protection Policy
# description: Protect sensitive files and directories from modification
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Edit", "Write"]
package cupcake.policies.opencode.file_protection

import rego.v1

# Protect .env files from being edited
deny contains decision if {
    input.tool_name == "Edit"
    file_path := input.tool_input.filePath
    
    endswith(file_path, ".env")
    
    decision := {
        "rule_id": "ENV_FILE_EDIT",
        "reason": concat("", ["Blocked edit of .env file: ", file_path, ". Use secure secrets management."]),
        "severity": "HIGH"
    }
}

# Protect .env files from being created
deny contains decision if {
    input.tool_name == "Write"
    file_path := input.tool_input.filePath
    
    endswith(file_path, ".env")
    
    decision := {
        "rule_id": "ENV_FILE_CREATE",
        "reason": concat("", ["Blocked creation of .env file: ", file_path, ". Creating .env files via AI can expose secrets."]),
        "severity": "HIGH"
    }
}

# Protect secrets files
deny contains decision if {
    input.tool_name in ["Edit", "Write"]
    file_path := input.tool_input.filePath
    
    secret_patterns := ["secret", "password", "credential", "token", "key."]
    some pattern in secret_patterns
    contains(lower(file_path), pattern)
    
    decision := {
        "rule_id": "SECRET_FILE_PROTECTION",
        "reason": concat("", ["File path suggests secrets: ", file_path, ". Use proper secrets management."]),
        "severity": "HIGH"
    }
}

# Warn on nix configuration changes
ask contains decision if {
    input.tool_name in ["Edit", "Write"]
    file_path := input.tool_input.filePath
    
    endswith(file_path, ".nix")
    
    critical_paths := ["/etc/nix", "flake.nix", "configuration.nix"]
    some path in critical_paths
    contains(file_path, path)
    
    decision := {
        "rule_id": "NIX_CONFIG_CHANGE",
        "reason": concat("", ["Modifying critical Nix configuration: ", file_path, ". This may break your system."]),
        "question": "Have you reviewed this change carefully?",
        "severity": "MEDIUM"
    }
}

# Warn on package.json/Cargo.toml dependency changes
ask contains decision if {
    input.tool_name == "Edit"
    file_path := input.tool_input.filePath
    
    dependency_files := ["package.json", "Cargo.toml", "Gemfile", "requirements.txt"]
    some dep_file in dependency_files
    endswith(file_path, dep_file)
    
    old_string := input.tool_input.oldString
    new_string := input.tool_input.newString
    
    contains(old_string, "dependencies")
    contains(new_string, "dependencies")
    old_string != new_string
    
    decision := {
        "rule_id": "DEPENDENCY_CHANGE",
        "reason": concat("", ["Modifying dependencies in ", file_path, ". Review changes carefully."]),
        "question": "Have you reviewed these dependency changes?",
        "severity": "MEDIUM"
    }
}
