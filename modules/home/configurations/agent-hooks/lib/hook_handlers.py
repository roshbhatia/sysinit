"""Generic hook handler implementations."""

import os
import asyncio
from typing import Optional, Dict, Any
from pathlib import Path


class HookHandlers:
    """Generic hook handler implementations for all agent platforms."""

    def __init__(self, nvim_client, config, logger):
        """
        Initialize hook handlers.

        Args:
            nvim_client: NeovimClient instance.
            config: HookConfig instance.
            logger: HookLogger instance.
        """
        self.nvim = nvim_client
        self.config = config
        self.logger = logger

    def before_read_file(self, file_path: str) -> Dict[str, Any]:
        """
        Handle before file read hook.

        Opens file in Neovim buffer before agent reads it.

        Args:
            file_path: Path to file being read.

        Returns:
            Hook result with status.
        """
        try:
            self.logger.info(f"before_read_file: {file_path}")

            if not self.config.pre_open_files:
                self.logger.debug("pre_open_files disabled, skipping")
                return {"status": "skipped", "reason": "disabled"}

            if not os.path.exists(file_path):
                self.logger.debug(f"File does not exist: {file_path}")
                return {"status": "skipped", "reason": "file_not_found"}

            # Open file in buffer (without focusing)
            success = self.nvim.open_file(file_path, focus=False)

            if success:
                self.logger.info(f"Opened file in buffer: {file_path}")
                return {"status": "success", "action": "opened", "file": file_path}
            else:
                self.logger.warn(f"Failed to open file: {file_path}")
                return {"status": "failed", "reason": "nvim_error"}

        except Exception as e:
            self.logger.exception("before_read_file error", e)
            return {"status": "error", "reason": str(e)}

    def after_write_file(self, file_path: str) -> Dict[str, Any]:
        """
        Handle after file write hook.

        Reloads buffer and optionally enables diff mode after agent writes file.

        Args:
            file_path: Path to file that was written.

        Returns:
            Hook result with status.
        """
        try:
            self.logger.info(f"after_write_file: {file_path}")

            if not self.config.auto_reload:
                self.logger.debug("auto_reload disabled, skipping")
                return {"status": "skipped", "reason": "disabled"}

            actions = []

            # Reload buffer
            if self.nvim.reload_buffer(file_path):
                self.logger.info(f"Reloaded buffer: {file_path}")
                actions.append("reloaded")
            else:
                # If buffer doesn't exist, try to open it
                if self.nvim.open_file(file_path, focus=False):
                    self.logger.info(f"Opened new buffer: {file_path}")
                    actions.append("opened")

            # Enable diff mode if configured
            if self.config.diff_mode and actions:
                if self.nvim.enable_diff_mode(file_path):
                    self.logger.info(f"Enabled diff mode: {file_path}")
                    actions.append("diff_enabled")

            if actions:
                return {
                    "status": "success",
                    "actions": actions,
                    "file": file_path,
                }
            else:
                return {"status": "skipped", "reason": "no_buffer"}

        except Exception as e:
            self.logger.exception("after_write_file error", e)
            return {"status": "error", "reason": str(e)}

    def before_shell_exec(self, command: str, cwd: Optional[str] = None) -> Dict[str, Any]:
        """
        Handle before shell execution hook.

        Sends notification to Neovim about command execution.

        Args:
            command: Shell command being executed.
            cwd: Working directory for command.

        Returns:
            Hook result with status.
        """
        try:
            self.logger.info(f"before_shell_exec: {command}")

            # Send notification to Neovim
            message = f"Agent executing: {command}"
            if cwd:
                message += f" (in {cwd})"

            success = self.nvim.send_notification(message, level="info")

            if success:
                return {
                    "status": "success",
                    "action": "notified",
                    "command": command,
                }
            else:
                return {"status": "skipped", "reason": "nvim_unavailable"}

        except Exception as e:
            self.logger.exception("before_shell_exec error", e)
            return {"status": "error", "reason": str(e)}

    def before_mcp_exec(
        self, server: str, method: str, params: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Handle before MCP execution hook.

        Sends notification to Neovim about MCP operation.

        Args:
            server: MCP server name.
            method: MCP method being called.
            params: Optional method parameters.

        Returns:
            Hook result with status.
        """
        try:
            self.logger.info(f"before_mcp_exec: {server}.{method}")

            # Send notification to Neovim
            message = f"Agent MCP call: {server}.{method}"

            success = self.nvim.send_notification(message, level="info")

            if success:
                return {
                    "status": "success",
                    "action": "notified",
                    "server": server,
                    "method": method,
                }
            else:
                return {"status": "skipped", "reason": "nvim_unavailable"}

        except Exception as e:
            self.logger.exception("before_mcp_exec error", e)
            return {"status": "error", "reason": str(e)}

    def after_read_file(self, file_path: str, content: Optional[str] = None) -> Dict[str, Any]:
        """
        Handle after file read hook.

        Currently a no-op but available for future extensions.

        Args:
            file_path: Path to file that was read.
            content: Optional file content.

        Returns:
            Hook result with status.
        """
        try:
            self.logger.debug(f"after_read_file: {file_path}")
            return {"status": "success", "action": "none"}
        except Exception as e:
            self.logger.exception("after_read_file error", e)
            return {"status": "error", "reason": str(e)}

    def before_write_file(
        self, file_path: str, content: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Handle before file write hook.

        Currently a no-op but available for future extensions.

        Args:
            file_path: Path to file being written.
            content: Optional file content being written.

        Returns:
            Hook result with status.
        """
        try:
            self.logger.debug(f"before_write_file: {file_path}")
            return {"status": "success", "action": "none"}
        except Exception as e:
            self.logger.exception("before_write_file error", e)
            return {"status": "error", "reason": str(e)}


async def async_handler(handler_func, *args, **kwargs):
    """
    Run handler asynchronously.

    Args:
        handler_func: Handler function to run.
        *args: Positional arguments.
        **kwargs: Keyword arguments.

    Returns:
        Handler result.
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, handler_func, *args, **kwargs)
