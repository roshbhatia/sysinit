# METADATA
# scope: package
# title: Nix Workflow Protection
# description: Protect Nix builds and ensure proper workflow
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.nix_workflow

import rego.v1

# Require nix build before nix refresh
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    refresh_commands := ["nix:refresh", "darwin-rebuild switch", "nixos-rebuild switch"]
    some refresh in refresh_commands
    contains(command, refresh)
    
    decision := {
        "rule_id": "NIX_BUILD_BEFORE_REFRESH",
        "reason": "You are about to apply system changes. Ensure you ran 'task nix:build' first.",
        "question": "Have you tested this configuration with nix:build?",
        "severity": "HIGH"
    }
}

# Warn on direct nix store modifications
deny contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "/nix/store")
    regex.match(`(rm|mv|chmod|chown|cp).*/nix/store`, command)
    
    decision := {
        "rule_id": "NIX_STORE_MODIFICATION",
        "reason": "Direct modification of /nix/store is prohibited. Use nix commands instead.",
        "severity": "CRITICAL"
    }
}

# Block nix-collect-garbage without confirmation
ask contains decision if {
    input.tool_name == "Bash"
    command := input.tool_input.command
    
    contains(command, "nix-collect-garbage")
    contains(command, "-d")
    
    decision := {
        "rule_id": "NIX_GARBAGE_DELETE",
        "reason": "This will delete all old Nix generations. You won't be able to rollback.",
        "question": "Are you sure you want to delete all old generations?",
        "severity": "HIGH"
    }
}
