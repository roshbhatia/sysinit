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

# Suggest using merge editor for git commits to enable review
add_context contains context if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	# Match git commit commands
	regex.match(`^\s*git\s+commit`, command)

	# Don't suggest for commands that already use --edit or open editor
	not contains(command, "--edit")
	not contains(command, "--no-edit")

	context := "Tip: Use the merge editor to review commits before they're created. Allows you to audit and reject if needed."
}

# NOTE: No deny rules - OpenCode native 'ask' handles confirmations
# Cupcake only provides educational suggestions via add_context
