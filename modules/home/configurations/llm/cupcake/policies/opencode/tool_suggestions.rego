# METADATA
# scope: package
# title: Tool Suggestions
# description: Suggest better modern alternatives to traditional Unix tools
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.tool_suggestions

import rego.v1

# Suggest ripgrep instead of grep
add_context contains context if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	# Only suggest for plain grep, not complex pipelines
	regex.match(`^\s*grep\s+`, command)
	not contains(command, "|")

	context := "Consider using 'rg' (ripgrep) instead of grep for faster searches with better defaults."
}

# Suggest fd instead of find
add_context contains context if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	regex.match(`^\s*find\s+`, command)
	not contains(command, "-exec")
	not contains(command, "-delete")

	context := "Consider using 'fd' instead of find for simpler syntax and faster searches."
}

# Suggest ast-grep for code pattern searches
add_context contains context if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	# Looking for function/class definitions
	regex.match(`(grep|rg).*\s+(function|class|def|fn)\s+`, command)

	context := "Consider using 'ast-grep' (or 'sg') for structural code searches that understand syntax."
}

# Block dangerous find operations
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "find")
	regex.match(`find.*-exec.*rm`, command)

	decision := {
		"rule_id": "FIND_EXEC_RM",
		"reason": "find -exec rm is dangerous. Use fd with explicit file review or interactive deletion.",
		"severity": "HIGH",
	}
}

# Block dangerous grep/sed inline edits
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	regex.match(`(grep|sed).*-i`, command)

	decision := {
		"rule_id": "GREP_SED_INPLACE",
		"reason": "In-place editing with grep/sed -i can cause data loss. Use the Edit tool or ast-grep --rewrite with review.",
		"severity": "MEDIUM",
	}
}

# Block ast-grep rewrite without review
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "ast-grep")
	contains(command, "--rewrite")
	not contains(command, "--interactive")

	decision := {
		"rule_id": "ASTGREP_NO_REVIEW",
		"reason": "ast-grep --rewrite without --interactive can modify many files. Use --interactive flag or the Edit tool.",
		"severity": "MEDIUM",
	}
}
