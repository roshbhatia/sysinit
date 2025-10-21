"""Configuration management for agent hooks."""

import os
from typing import Optional
from dataclasses import dataclass


@dataclass
class HookConfig:
    """Configuration for agent hooks."""

    # Core settings
    enabled: bool = True
    debug: bool = False
    socket_path: Optional[str] = None

    # Agent-specific toggles
    cursor_enabled: bool = True
    claude_enabled: bool = True
    opencode_enabled: bool = True

    # Feature flags
    diff_mode: bool = True
    auto_reload: bool = True
    pre_open_files: bool = True

    # Performance settings
    async_writes: bool = True
    timeout_ms: int = 200


def _get_bool_env(key: str, default: bool = False) -> bool:
    """
    Get boolean value from environment variable.

    Args:
        key: Environment variable name.
        default: Default value if not set.

    Returns:
        Boolean value.
    """
    value = os.environ.get(key, "").lower()
    if not value:
        return default
    return value in ("true", "1", "yes", "on")


def _get_int_env(key: str, default: int = 0) -> int:
    """
    Get integer value from environment variable.

    Args:
        key: Environment variable name.
        default: Default value if not set.

    Returns:
        Integer value.
    """
    value = os.environ.get(key, "")
    if not value:
        return default
    try:
        return int(value)
    except ValueError:
        return default


def load_config() -> HookConfig:
    """
    Load configuration from environment variables.

    Environment variables use SYSINIT_AGENT_HOOKS_ prefix.

    Returns:
        HookConfig instance.
    """
    return HookConfig(
        # Core settings
        enabled=_get_bool_env("SYSINIT_AGENT_HOOKS_ENABLED", True),
        debug=_get_bool_env("SYSINIT_AGENT_HOOKS_DEBUG", False),
        socket_path=os.environ.get("SYSINIT_AGENT_HOOKS_SOCKET_PATH") or None,
        # Agent-specific toggles
        cursor_enabled=_get_bool_env("SYSINIT_AGENT_HOOKS_CURSOR_ENABLED", True),
        claude_enabled=_get_bool_env("SYSINIT_AGENT_HOOKS_CLAUDE_ENABLED", True),
        opencode_enabled=_get_bool_env("SYSINIT_AGENT_HOOKS_OPENCODE_ENABLED", True),
        # Feature flags
        diff_mode=_get_bool_env("SYSINIT_AGENT_HOOKS_DIFF_MODE", True),
        auto_reload=_get_bool_env("SYSINIT_AGENT_HOOKS_AUTO_RELOAD", True),
        pre_open_files=_get_bool_env("SYSINIT_AGENT_HOOKS_PRE_OPEN_FILES", True),
        # Performance settings
        async_writes=_get_bool_env("SYSINIT_AGENT_HOOKS_ASYNC_WRITES", True),
        timeout_ms=_get_int_env("SYSINIT_AGENT_HOOKS_TIMEOUT_MS", 200),
    )


def is_enabled_for_agent(config: HookConfig, agent_type: str) -> bool:
    """
    Check if hooks are enabled for specific agent.

    Args:
        config: Hook configuration.
        agent_type: Agent type (cursor, claude, opencode).

    Returns:
        True if enabled for this agent.
    """
    if not config.enabled:
        return False

    agent_type = agent_type.lower()
    if agent_type == "cursor":
        return config.cursor_enabled
    elif agent_type == "claude":
        return config.claude_enabled
    elif agent_type == "opencode":
        return config.opencode_enabled

    # Unknown agent - default to enabled if master switch is on
    return True
