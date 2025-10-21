"""Logging utilities for agent hooks."""

import sys
import json
from datetime import datetime
from typing import Optional, Dict, Any


class HookLogger:
    """Structured logger for hook operations."""

    def __init__(self, debug: bool = False, hook_name: Optional[str] = None):
        """
        Initialize logger.

        Args:
            debug: Enable debug logging.
            hook_name: Name of the hook for context.
        """
        self.debug_enabled = debug
        self.hook_name = hook_name or "agent-hook"

    def _log(
        self, level: str, message: str, extra: Optional[Dict[str, Any]] = None
    ):
        """
        Write structured log entry to stderr.

        Args:
            level: Log level (debug, info, warn, error).
            message: Log message.
            extra: Additional context data.
        """
        if level == "debug" and not self.debug_enabled:
            return

        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": level,
            "hook": self.hook_name,
            "message": message,
        }

        if extra:
            entry.update(extra)

        # Write to stderr as JSON
        print(json.dumps(entry), file=sys.stderr)

    def debug(self, message: str, **kwargs):
        """Log debug message."""
        self._log("debug", message, kwargs if kwargs else None)

    def info(self, message: str, **kwargs):
        """Log info message."""
        self._log("info", message, kwargs if kwargs else None)

    def warn(self, message: str, **kwargs):
        """Log warning message."""
        self._log("warn", message, kwargs if kwargs else None)

    def error(self, message: str, **kwargs):
        """Log error message."""
        self._log("error", message, kwargs if kwargs else None)

    def exception(self, message: str, exc: Exception, **kwargs):
        """
        Log exception with traceback.

        Args:
            message: Error message.
            exc: Exception instance.
            **kwargs: Additional context.
        """
        extra = kwargs.copy() if kwargs else {}
        extra["exception"] = str(exc)
        extra["exception_type"] = type(exc).__name__
        self._log("error", message, extra)


def create_logger(debug: bool = False, hook_name: Optional[str] = None) -> HookLogger:
    """
    Factory function to create logger.

    Args:
        debug: Enable debug logging.
        hook_name: Hook name for context.

    Returns:
        HookLogger instance.
    """
    return HookLogger(debug=debug, hook_name=hook_name)
