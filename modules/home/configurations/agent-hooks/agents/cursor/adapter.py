"""Cursor Agent adapter for hook input/output handling."""

import sys
import json
from typing import Dict, Any, Optional, Tuple


def detect_agent() -> bool:
    """
    Detect if running under Cursor Agent.

    Returns:
        True if Cursor Agent detected.
    """
    # Cursor sets specific environment variables
    return any(
        [
            "CURSOR_" in key
            for key in ["CURSOR_USER", "CURSOR_SESSION", "CURSOR_WORKSPACE"]
            if key in sys.environ
        ]
    ) or "cursor" in sys.executable.lower()


def parse_before_read_file() -> Optional[str]:
    """
    Parse before_read_file hook input from Cursor.

    Cursor passes file path as first argument.

    Returns:
        File path or None.
    """
    if len(sys.argv) > 1:
        return sys.argv[1]
    return None


def parse_after_write_file() -> Optional[str]:
    """
    Parse after_write_file hook input from Cursor.

    Cursor passes file path as first argument.

    Returns:
        File path or None.
    """
    if len(sys.argv) > 1:
        return sys.argv[1]
    return None


def parse_before_shell_exec() -> Optional[Tuple[str, Optional[str]]]:
    """
    Parse before_shell_exec hook input from Cursor.

    Cursor passes command as first arg, optionally cwd as second.

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
    Parse before_mcp_exec hook input from Cursor.

    Cursor passes server, method, and optionally params as JSON.

    Returns:
        Tuple of (server, method, params) or None.
    """
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
    Format hook result for Cursor output.

    Cursor expects JSON output on stdout.

    Args:
        result: Hook result dictionary.

    Returns:
        Formatted output string.
    """
    return json.dumps(result)


def should_exit_zero() -> bool:
    """
    Determine if hook should always exit with code 0.

    Cursor expects hooks to exit 0 to avoid blocking operations.

    Returns:
        True (always exit 0 for Cursor).
    """
    return True
