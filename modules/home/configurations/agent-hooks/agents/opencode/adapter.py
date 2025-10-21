"""OpenCode adapter for hook input/output handling."""

import sys
import json
import os
from typing import Dict, Any, Optional, Tuple


def detect_agent() -> bool:
    """
    Detect if running under OpenCode.

    Returns:
        True if OpenCode detected.
    """
    # OpenCode sets specific environment variables
    return any(
        [key in os.environ for key in ["OPENCODE_SESSION", "OPENCODE_WORKSPACE"]]
    ) or "opencode" in sys.executable.lower()


def parse_before_read_file() -> Optional[str]:
    """
    Parse before_read_file hook input from OpenCode.

    OpenCode uses JSON on stdin.

    Returns:
        File path or None.
    """
    try:
        if not sys.stdin.isatty():
            data = json.loads(sys.stdin.read())
            return data.get("file_path") or data.get("path")
    except (json.JSONDecodeError, KeyError):
        pass

    # Fallback to command-line args
    if len(sys.argv) > 1:
        return sys.argv[1]
    return None


def parse_after_write_file() -> Optional[str]:
    """
    Parse after_write_file hook input from OpenCode.

    OpenCode uses JSON on stdin.

    Returns:
        File path or None.
    """
    try:
        if not sys.stdin.isatty():
            data = json.loads(sys.stdin.read())
            return data.get("file_path") or data.get("path")
    except (json.JSONDecodeError, KeyError):
        pass

    # Fallback to command-line args
    if len(sys.argv) > 1:
        return sys.argv[1]
    return None


def parse_before_shell_exec() -> Optional[Tuple[str, Optional[str]]]:
    """
    Parse before_shell_exec hook input from OpenCode.

    OpenCode uses JSON on stdin.

    Returns:
        Tuple of (command, cwd) or None.
    """
    try:
        if not sys.stdin.isatty():
            data = json.loads(sys.stdin.read())
            return (data.get("command"), data.get("cwd"))
    except (json.JSONDecodeError, KeyError):
        pass

    # Fallback to command-line args
    if len(sys.argv) > 1:
        command = sys.argv[1]
        cwd = sys.argv[2] if len(sys.argv) > 2 else None
        return (command, cwd)
    return None


def parse_before_mcp_exec() -> Optional[Tuple[str, str, Optional[Dict[str, Any]]]]:
    """
    Parse before_mcp_exec hook input from OpenCode.

    OpenCode uses JSON on stdin.

    Returns:
        Tuple of (server, method, params) or None.
    """
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
    Format hook result for OpenCode output.

    OpenCode expects JSON output on stdout.

    Args:
        result: Hook result dictionary.

    Returns:
        Formatted output string.
    """
    return json.dumps(result, indent=2)


def should_exit_zero() -> bool:
    """
    Determine if hook should always exit with code 0.

    OpenCode expects hooks to exit 0 to avoid blocking operations.

    Returns:
        True (always exit 0 for OpenCode).
    """
    return True
