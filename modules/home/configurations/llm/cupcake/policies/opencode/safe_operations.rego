# METADATA
# scope: package
# title: Safe Operations Validation
# description: Allow safe operations and block dangerous patterns with clear guidance
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.safe_operations

import rego.v1

# Block dangerous search tool flags
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	search_tools := ["rg", "ripgrep", "fd", "ag", "find", "grep"]
	some tool in search_tools
	contains(command, tool)

	dangerous_flags := {
		"-exec": "Execute arbitrary commands on matches",
		"-delete": "Delete matched files",
		"--exec": "Execute arbitrary commands on matches",
	}

	some flag, desc in dangerous_flags
	contains(command, flag)

	decision := {
		"rule_id": "BLOCK_DANGEROUS_SEARCH_FLAGS",
		"reason": sprintf("Blocked: %s flag (%s). Use read-only search without modification flags.", [flag, desc]),
	}
}

# Block in-place editing with sed/awk
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	edit_patterns := [
		{
			"tool": "sed",
			"pattern": `sed\s+.*-i`,
			"message": "Use Edit tool for file modifications instead of sed -i",
		},
		{
			"tool": "awk",
			"pattern": `awk\s+.*-i\s+inplace`,
			"message": "Use Edit tool for file modifications instead of awk -i inplace",
		},
	]

	some pattern_obj in edit_patterns
	regex.match(pattern_obj.pattern, command)

	decision := {
		"rule_id": "BLOCK_INPLACE_EDIT",
		"reason": sprintf("Blocked: %s in-place editing. %s", [pattern_obj.tool, pattern_obj.message]),
	}
}

# Block ast-grep rewrite operations
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "ast-grep")
	contains(command, "--rewrite")

	decision := {
		"rule_id": "BLOCK_ASTGREP_REWRITE",
		"reason": "Blocked: ast-grep --rewrite. Use Edit tool for code modifications instead.",
	}
}

# Block dangerous nix operations
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	startswith(trim_space(command), "nix")

	dangerous_nix := {
		"nix-env -i": "System modification",
		"nix-env --install": "System modification",
		"nix profile install": "Profile modification",
		"nix profile remove": "Profile modification",
		"nix-collect-garbage": "Garbage collection",
		"nix store delete": "Store deletion",
	}

	some pattern, desc in dangerous_nix
	startswith(trim_space(command), pattern)

	decision := {
		"rule_id": "BLOCK_DANGEROUS_NIX",
		"reason": sprintf("Blocked: %s (%s). Use 'task nix:*' commands or request user confirmation.", [pattern, desc]),
	}
}

# Allow safe git read operations
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	safe_git_commands := [
		"git status",
		"git diff",
		"git log",
		"git show",
		"git branch",
		"git remote",
		"git fetch",
		"git ls-files",
		"git rev-parse",
		"git describe",
	]

	some cmd in safe_git_commands
	startswith(trim_space(command), cmd)

	decision := {
		"rule_id": "SAFE_GIT_READ",
		"reason": "Safe git read operation",
	}
}

# Allow beads operations
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	startswith(trim_space(command), "bd ")

	decision := {
		"rule_id": "SAFE_BEADS",
		"reason": "Beads operation",
	}
}

# Allow safe search tools (read-only)
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	safe_search_commands := [
		"rg ",
		"ripgrep ",
		"fd ",
		"ag ",
		"find ",
		"grep ",
	]

	some cmd in safe_search_commands
	startswith(trim_space(command), cmd)

	# Ensure no dangerous flags
	not contains(command, "-exec")
	not contains(command, "--exec")
	not contains(command, "-delete")

	decision := {
		"rule_id": "SAFE_SEARCH",
		"reason": "Safe read-only search operation",
	}
}

# Allow safe awk/sed (read-only)
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	text_tools := ["awk ", "sed "]
	some tool in text_tools
	startswith(trim_space(command), tool)

	# Ensure no in-place editing
	not regex.match(`sed\s+.*-i`, command)
	not regex.match(`awk\s+.*-i\s+inplace`, command)

	decision := {
		"rule_id": "SAFE_TEXT_PROCESSING",
		"reason": "Safe read-only text processing",
	}
}

# Allow ast-grep search (not rewrite)
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "ast-grep")
	not contains(command, "--rewrite")

	decision := {
		"rule_id": "SAFE_ASTGREP",
		"reason": "Safe ast-grep search operation",
	}
}

# Allow safe nix read operations
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	safe_nix_commands := [
		"nix flake check",
		"nix flake show",
		"nix flake metadata",
		"nix eval",
		"nix search",
		"nix-instantiate",
		"nix show-config",
		"nix path-info",
	]

	some cmd in safe_nix_commands
	startswith(trim_space(command), cmd)

	decision := {
		"rule_id": "SAFE_NIX_READ",
		"reason": "Safe nix read operation",
	}
}

# Allow safe task read operations
allow contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	task_read_patterns := [
		"task --list",
		"task --summary",
		"task -l",
	]

	some pattern in task_read_patterns
	startswith(trim_space(command), pattern)

	decision := {
		"rule_id": "SAFE_TASK_READ",
		"reason": "Safe task read operation",
	}
}
