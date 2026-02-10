# METADATA
# scope: package
# title: Bash Command Protection
# description: Smart bash command filtering with safety guardrails
# custom:
#   routing:
#     required_events: ["PreToolUse"]
#     required_tools: ["Bash"]
package cupcake.policies.opencode.bash_protection

import rego.v1

# Helper: Check if command contains pattern
contains_pattern(cmd, pattern) if {
	regex.match(pattern, cmd)
}

# Helper: Check if reading sensitive files
reads_sensitive_file(cmd) if {
	contains_pattern(cmd, `(cat|bat|head|tail|less|more)\s+.*\.env`)
}

reads_sensitive_file(cmd) if {
	contains_pattern(cmd, `(cat|bat|head|tail|less|more)\s+.*\.git(ignore|excludes)`)
}

# Helper: Check if operating on system paths
operates_on_system_path(cmd) if {
	contains_pattern(cmd, `/etc/`)
}

operates_on_system_path(cmd) if {
	contains_pattern(cmd, `/System/`)
}

operates_on_system_path(cmd) if {
	contains_pattern(cmd, `/nix/store/`)
}

operates_on_system_path(cmd) if {
	contains_pattern(cmd, `~/.ssh/`)
}

# DENY: Reading sensitive files
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command
	reads_sensitive_file(command)

	decision := {
		"rule_id": "BASH_READ_SENSITIVE_FILE",
		"reason": "Cannot read .env files or gitignored files. These contain sensitive data that should remain private.",
		"severity": "CRITICAL",
	}
}

# DENY: Destructive rm/rmdir (except /tmp)
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "rm")
	not contains(command, "/tmp/")
	not contains(command, "/var/tmp/")

	decision := {
		"rule_id": "BASH_DESTRUCTIVE_RM",
		"reason": "Destructive rm/rmdir operations are blocked except in /tmp. Use file management tools or be very explicit about what you're deleting.",
		"severity": "CRITICAL",
	}
}

# DENY: git reset --hard
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "git reset")
	contains(command, "--hard")

	decision := {
		"rule_id": "BASH_GIT_RESET_HARD",
		"reason": "Hard git resets can lose uncommitted work. Use git stash or explicit commits instead.",
		"severity": "HIGH",
	}
}

# DENY: git clean -fd
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "git clean")
	regex.match(`git\s+clean.*-[fd]`, command)

	decision := {
		"rule_id": "BASH_GIT_CLEAN",
		"reason": "git clean with -f or -d removes untracked files permanently. Ensure you want to delete these files.",
		"severity": "HIGH",
	}
}

# DENY: git push --force to main/master
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "git push")
	contains(command, "--force")
	regex.match(`(main|master)`, command)

	decision := {
		"rule_id": "BASH_GIT_FORCE_PUSH_MAIN",
		"reason": "Force pushing to main/master is prohibited. This rewrites history and can break team workflows.",
		"severity": "CRITICAL",
	}
}

# DENY: chmod/chown on system paths
deny contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	regex.match(`(chmod|chown)`, command)
	operates_on_system_path(command)

	decision := {
		"rule_id": "BASH_SYSTEM_PERMISSION_CHANGE",
		"reason": "Cannot modify permissions on system paths (/etc, /System, /nix/store, ~/.ssh). These are protected.",
		"severity": "CRITICAL",
	}
}

# ASK: File operations (mkdir, touch, cp, mv)
ask contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	regex.match(`^\s*(mkdir|touch|cp|mv)\s+`, command)

	decision := {
		"rule_id": "BASH_FILE_OPERATION",
		"reason": "File system modification requested.",
		"question": "Create/modify files with this command?",
		"severity": "MEDIUM",
	}
}

# ASK: Git write operations
ask contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	regex.match(`git\s+(add|commit|push|merge|rebase)`, command)

	decision := {
		"rule_id": "BASH_GIT_WRITE",
		"reason": "Git write operation requested.",
		"question": "Proceed with git operation?",
		"severity": "MEDIUM",
	}
}

# ASK: Task execution
ask contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	startswith(trim_space(command), "task ")

	decision := {
		"rule_id": "BASH_TASK_EXECUTION",
		"reason": "Task execution can run multiple commands and build operations.",
		"question": "Execute this task?",
		"severity": "MEDIUM",
	}
}

# ASK: Nix builds (long-running, resource intensive)
ask contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	regex.match(`(nix-build|nix\s+build|darwin-rebuild\s+build)`, command)

	decision := {
		"rule_id": "BASH_NIX_BUILD",
		"reason": "Nix builds are resource-intensive and may take several minutes.",
		"question": "Proceed with build?",
		"severity": "LOW",
	}
}

# ASK: rm in /tmp (allow with confirmation)
ask contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "rm")
	contains(command, "/tmp/")

	decision := {
		"rule_id": "BASH_RM_TMP",
		"reason": "Removing files from /tmp.",
		"question": "Delete temporary files?",
		"severity": "LOW",
	}
}

# ASK: git push --force to non-main branches
ask contains decision if {
	input.tool_name == "Bash"
	command := input.tool_input.command

	contains(command, "git push")
	contains(command, "--force")
	not regex.match(`(main|master)`, command)

	decision := {
		"rule_id": "BASH_GIT_FORCE_PUSH_BRANCH",
		"reason": "Force pushing rewrites git history.",
		"question": "Force push to this branch?",
		"severity": "MEDIUM",
	}
}

# ALLOW: File inspection commands (safe read-only)
# These are implicitly allowed by not matching any deny/ask rules

# ALLOW: Search commands (safe read-only)
# rg, grep, ag, fd, find (without -exec/-delete) - implicitly allowed

# ALLOW: Git read operations
# git status, git diff, git log, git show, git branch, git remote - implicitly allowed

# ALLOW: Code analysis tools
# ast-grep search, sg search - implicitly allowed

# ALLOW: Beads operations (all allowed without confirmation per user request)
# bd create, bd update, bd close, bd dep, bd ready, bd list, bd show - implicitly allowed

# ALLOW: Nix read operations
# nix flake check, nix eval, nix search - implicitly allowed

# ALLOW: System info commands
# pwd, whoami, hostname, uname, date, df, du - implicitly allowed
