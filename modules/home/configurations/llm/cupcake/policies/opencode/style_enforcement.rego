# METADATA
# scope: package
# title: AGENTS.md Style Enforcement
# description: Enforce code style guidelines from AGENTS.md
# custom:
#   routing:
#     required_events: ["PreToolUse", "PostToolUse"]
#     required_tools: ["Edit", "Write"]
package cupcake.policies.opencode.style_enforcement

import rego.v1

# Helper: Check if file needs specific formatter
needs_nix_format(file) if {
	endswith(file, ".nix")
}

needs_lua_format(file) if {
	endswith(file, ".lua")
}

needs_sh_format(file) if {
	endswith(file, ".sh")
}

# Helper: Check if editing Nix files
editing_nix_file if {
	input.tool_name == "Edit"
	file := input.tool_input.filePath
	needs_nix_format(file)
}

editing_nix_file if {
	input.tool_name == "Write"
	file := input.tool_input.filePath
	needs_nix_format(file)
}

# Helper: Check if editing Lua files
editing_lua_file if {
	input.tool_name == "Edit"
	file := input.tool_input.filePath
	needs_lua_format(file)
}

editing_lua_file if {
	input.tool_name == "Write"
	file := input.tool_input.filePath
	needs_lua_format(file)
}

# Helper: Check if editing shell scripts
editing_sh_file if {
	input.tool_name == "Edit"
	file := input.tool_input.filePath
	needs_sh_format(file)
}

editing_sh_file if {
	input.tool_name == "Write"
	file := input.tool_input.filePath
	needs_sh_format(file)
}

# Helper: Check for emoji in content
contains_emoji(content) if {
	# Common emoji patterns (this is a simplified check)
	regex.match(`[\x{1F600}-\x{1F64F}]`, content)
}

contains_emoji(content) if {
	regex.match(`[\x{1F300}-\x{1F5FF}]`, content)
}

contains_emoji(content) if {
	regex.match(`[\x{1F680}-\x{1F6FF}]`, content)
}

contains_emoji(content) if {
	regex.match(`[\x{2600}-\x{26FF}]`, content)
}

contains_emoji(content) if {
	regex.match(`[\x{2700}-\x{27BF}]`, content)
}

# DENY: Emojis in code (AGENTS.md: "No Emojis: Strictly enforced")
deny contains decision if {
	input.tool_name == "Edit"
	content := input.tool_input.newString
	contains_emoji(content)

	decision := {
		"rule_id": "STYLE_NO_EMOJI_EDIT",
		"reason": "AGENTS.md strictly forbids emojis in code. Remove all emoji characters.",
		"severity": "HIGH",
	}
}

deny contains decision if {
	input.tool_name == "Write"
	content := input.tool_input.content
	contains_emoji(content)

	decision := {
		"rule_id": "STYLE_NO_EMOJI_WRITE",
		"reason": "AGENTS.md strictly forbids emojis in code. Remove all emoji characters.",
		"severity": "HIGH",
	}
}

# ASK: Editing Nix files without checking formatting first
ask contains decision if {
	editing_nix_file

	decision := {
		"rule_id": "STYLE_NIX_FORMAT_REMINDER",
		"reason": "Editing Nix file. Remember AGENTS.md style: nixfmt --width=100, camelCase for variables, snake_case for files.",
		"question": "Have you considered the Nix formatting requirements?",
		"severity": "LOW",
	}
}

# ASK: Editing Lua files without checking style
ask contains decision if {
	editing_lua_file

	decision := {
		"rule_id": "STYLE_LUA_FORMAT_REMINDER",
		"reason": "Editing Lua file. Remember AGENTS.md style: stylua (column_width=100), snake_case for vars/funcs, PascalCase for modules.",
		"question": "Have you considered the Lua formatting requirements?",
		"severity": "LOW",
	}
}

# ASK: Editing shell scripts without checking style
ask contains decision if {
	editing_sh_file

	decision := {
		"rule_id": "STYLE_SH_FORMAT_REMINDER",
		"reason": "Editing shell script. Remember AGENTS.md requirements: #!/usr/bin/env bash, set -euo pipefail, shfmt -i 2 -ci -sr -s -w.",
		"question": "Does this script have proper shebang and safety settings?",
		"severity": "LOW",
	}
}

# ASK: Writing new shell script - check if executable
ask contains decision if {
	input.tool_name == "Write"
	file := input.tool_input.filePath
	needs_sh_format(file)

	decision := {
		"rule_id": "STYLE_SH_EXECUTABLE",
		"reason": "AGENTS.md requires all .sh files must be executable. Run: chmod +x <file>",
		"question": "Will you make this shell script executable after writing?",
		"severity": "MEDIUM",
	}
}

# INFO: Remind about landing the plane workflow when session seems complete
# This would need to check signals like git_unpushed to be fully effective
# For now, it's just a reminder to use in policies that check commit status
