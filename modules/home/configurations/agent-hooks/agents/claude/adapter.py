"""Claude Code adapter for hook input/output handling."""

import sys
import json
import os
from typing import Dict, Any, Optional, Tuple


def detect_agent() -> bool:
    """
    Detect if running under Claude Code.

    Returns:
        True if Claude Code detected.
    """
    # Claude Code sets specific environment variables
    return any(
        [
            key in os.environ
            for key in ["CLAUDE_API_KEY", "CLAUDE_SESSION", "ANTHROPIC_API_KEY"]
        ]
    ) or "claude" in sys.executable.lower()


def parse_before_read_file() -> Optional[str]:
    """
    Parse before_read_file hook input from Claude Code.

    Claude Code passes file path as first argument.

    Returns:
        File path or None.
    """
    if len(sys.argv) > 1:
        return sys.argv[1]
    return None


def parse_after_write_file() -> Optional[str]:
    """
    Parse after_write_file hook input from Claude Code.

    Claude Code passes file path as first argument.

    Returns:
        File path or None.
    """
    if len(sys.argv) > 1:
        return sys.argv[1]
    return None


def parse_before_shell_exec() -> Optional[Tuple[str, Optional[str]]]:
    """
    Parse before_shell_exec hook input from Claude Code.

    Claude Code passes command as first arg, optionally cwd as second.

    Returns:
        Tuple of (command, cwd) or None.
    """
    if len(sys.argv) > 1:
        command = sys.argv[1]
        cwd = sys.argv[2] if len(sys.argv) > 2 else None
        return (command, cwd)
    return None


def parse_before_mcp_exec() -> Optional[Tuple[str, str, Optional[Dict[str, Any]]]]:
    """
    Parse before_mcp_exec hook input from Claude Code.

    Claude Code may use JSON on stdin for complex data.

    Returns:
        Tuple of (server, method, params) or None.
    """
    # Try reading from stdin first (Claude Code preference)
    try:
        if not sys.stdin.isatty():
            data = json.loads(sys.stdin.read())
            return (data.get("server"), data.get("method"), data.get("params"))
    except (json.JSONDecodeError, KeyError):
        pass

    # Fallback to command-line args
    if len(sys.argv) > 2:
        server = sys.argv[1]
        method = sys.argv[2]
        params = None
        if len(sys.argv) > 3:
            try:
                params = json.loads(sys.argv[3])
            except json.JSONDecodeError:
                pass
        return (server, method, params)
    return None


def format_output(result: Dict[str, Any]) -> str:
    """
    Format hook result for Claude Code output.

    Claude Code expects JSON output on stdout.

    Args:
        result: Hook result dictionary.

    Returns:
        Formatted output string.
    """
    return json.dumps(result, indent=2)


def should_exit_zero() -> bool:
    """
    Determine if hook should always exit with code 0.

    Claude Code expects hooks to exit 0 to avoid blocking operations.

    Returns:
        True (always exit 0 for Claude Code).
    """
    return True
