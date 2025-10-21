"""Neovim socket client for agent integrations."""

import os
import glob
from typing import Optional, List
from pathlib import Path


class NeovimClient:
    """Client for communicating with Neovim via socket/RPC."""

    def __init__(self, socket_path: Optional[str] = None, logger=None):
        """
        Initialize Neovim client.

        Args:
            socket_path: Optional explicit socket path. If None, will auto-discover.
            logger: Optional logger instance.
        """
        self.logger = logger
        self.socket_path = socket_path or self._discover_socket()
        self._nvim = None

    def _discover_socket(self) -> Optional[str]:
        """
        Discover Neovim socket path using standard detection strategy.

        Priority:
        1. $NVIM environment variable (when running from :terminal)
        2. $NVIM_LISTEN_ADDRESS (legacy)
        3. Default socket paths (/tmp/nvim.*/0)

        Returns:
            Socket path if found, None otherwise.
        """
        # Check $NVIM (highest priority - set when running from :terminal)
        if os.environ.get("NVIM"):
            socket = os.environ["NVIM"]
            if self._log_debug(f"Found socket via $NVIM: {socket}"):
                return socket

        # Check $NVIM_LISTEN_ADDRESS (legacy support)
        if os.environ.get("NVIM_LISTEN_ADDRESS"):
            socket = os.environ["NVIM_LISTEN_ADDRESS"]
            if self._log_debug(f"Found socket via $NVIM_LISTEN_ADDRESS: {socket}"):
                return socket

        # Search default socket locations
        socket_patterns = [
            "/tmp/nvim.*/0",  # Standard Unix socket pattern
            "/tmp/nvimsocket",  # Alternative common name
        ]

        for pattern in socket_patterns:
            matches = glob.glob(pattern)
            if matches:
                # Use most recently modified socket
                socket = max(matches, key=os.path.getmtime)
                if self._log_debug(f"Found socket via pattern {pattern}: {socket}"):
                    return socket

        self._log_debug("No Neovim socket found")
        return None

    def _log_debug(self, message: str) -> bool:
        """Log debug message if logger available. Returns True for chaining."""
        if self.logger:
            self.logger.debug(message)
        return True

    def _log_error(self, message: str):
        """Log error message if logger available."""
        if self.logger:
            self.logger.error(message)

    def connect(self) -> bool:
        """
        Connect to Neovim instance.

        Returns:
            True if connection successful, False otherwise.
        """
        if not self.socket_path:
            self._log_error("Cannot connect: no socket path available")
            return False

        try:
            import pynvim

            self._nvim = pynvim.attach("socket", path=self.socket_path)
            self._log_debug(f"Connected to Neovim at {self.socket_path}")
            return True
        except Exception as e:
            self._log_error(f"Failed to connect to Neovim: {e}")
            return False

    def is_connected(self) -> bool:
        """Check if currently connected to Neovim."""
        return self._nvim is not None

    def disconnect(self):
        """Disconnect from Neovim."""
        if self._nvim:
            try:
                self._nvim.close()
            except Exception as e:
                self._log_error(f"Error disconnecting: {e}")
            finally:
                self._nvim = None

    def open_file(self, file_path: str, focus: bool = False) -> bool:
        """
        Open file in Neovim buffer.

        Args:
            file_path: Path to file to open.
            focus: If True, switch to the buffer.

        Returns:
            True if successful, False otherwise.
        """
        if not self.is_connected():
            if not self.connect():
                return False

        try:
            abs_path = os.path.abspath(file_path)

            # Check if file is already open in a buffer
            for buf in self._nvim.buffers:
                buf_name = buf.name
                if buf_name and os.path.abspath(buf_name) == abs_path:
                    self._log_debug(f"File already open in buffer: {file_path}")
                    if focus:
                        # Switch to the buffer
                        self._nvim.command(f"buffer {buf.number}")
                    return True

            # Open in new buffer
            cmd = f"badd {abs_path}"
            self._nvim.command(cmd)

            if focus:
                self._nvim.command(f"buffer {abs_path}")

            self._log_debug(f"Opened file in buffer: {file_path}")
            return True
        except Exception as e:
            self._log_error(f"Failed to open file {file_path}: {e}")
            return False

    def reload_buffer(self, file_path: str) -> bool:
        """
        Reload buffer for given file path.

        Args:
            file_path: Path to file to reload.

        Returns:
            True if successful, False otherwise.
        """
        if not self.is_connected():
            if not self.connect():
                return False

        try:
            abs_path = os.path.abspath(file_path)

            # Find buffer by name
            for buf in self._nvim.buffers:
                buf_name = buf.name
                if buf_name and os.path.abspath(buf_name) == abs_path:
                    # Use :edit to reload
                    self._nvim.command(f"buffer {buf.number}")
                    self._nvim.command("edit")
                    self._log_debug(f"Reloaded buffer: {file_path}")
                    return True

            self._log_debug(f"Buffer not found for file: {file_path}")
            return False
        except Exception as e:
            self._log_error(f"Failed to reload buffer {file_path}: {e}")
            return False

    def enable_diff_mode(self, file_path: str) -> bool:
        """
        Enable diff mode for buffer.

        Args:
            file_path: Path to file.

        Returns:
            True if successful, False otherwise.
        """
        if not self.is_connected():
            if not self.connect():
                return False

        try:
            abs_path = os.path.abspath(file_path)

            # Find buffer and enable diff
            for buf in self._nvim.buffers:
                buf_name = buf.name
                if buf_name and os.path.abspath(buf_name) == abs_path:
                    self._nvim.command(f"buffer {buf.number}")
                    self._nvim.command("diffthis")
                    self._log_debug(f"Enabled diff mode: {file_path}")
                    return True

            return False
        except Exception as e:
            self._log_error(f"Failed to enable diff mode for {file_path}: {e}")
            return False

    def send_notification(self, message: str, level: str = "info") -> bool:
        """
        Send notification to Neovim.

        Args:
            message: Notification message.
            level: Notification level (info, warn, error).

        Returns:
            True if successful, False otherwise.
        """
        if not self.is_connected():
            if not self.connect():
                return False

        try:
            # Use vim.notify if available (Neovim 0.7+)
            lua_cmd = f'vim.notify("{message}", vim.log.levels.{level.upper()})'
            self._nvim.exec_lua(lua_cmd)
            return True
        except Exception as e:
            # Fallback to echo
            try:
                self._nvim.command(f'echo "{message}"')
                return True
            except Exception as e2:
                self._log_error(f"Failed to send notification: {e2}")
                return False

    def execute_command(self, command: str) -> bool:
        """
        Execute Vim command.

        Args:
            command: Vim command to execute.

        Returns:
            True if successful, False otherwise.
        """
        if not self.is_connected():
            if not self.connect():
                return False

        try:
            self._nvim.command(command)
            return True
        except Exception as e:
            self._log_error(f"Failed to execute command '{command}': {e}")
            return False

    def get_current_buffer(self) -> Optional[str]:
        """
        Get current buffer file path.

        Returns:
            File path of current buffer, or None.
        """
        if not self.is_connected():
            if not self.connect():
                return None

        try:
            buf = self._nvim.current.buffer
            return buf.name if buf.name else None
        except Exception as e:
            self._log_error(f"Failed to get current buffer: {e}")
            return None

    def list_buffers(self) -> List[str]:
        """
        List all open buffer file paths.

        Returns:
            List of file paths.
        """
        if not self.is_connected():
            if not self.connect():
                return []

        try:
            return [buf.name for buf in self._nvim.buffers if buf.name]
        except Exception as e:
            self._log_error(f"Failed to list buffers: {e}")
            return []


def create_client(socket_path: Optional[str] = None, logger=None) -> NeovimClient:
    """
    Factory function to create Neovim client.

    Args:
        socket_path: Optional socket path override.
        logger: Optional logger instance.

    Returns:
        NeovimClient instance.
    """
    return NeovimClient(socket_path=socket_path, logger=logger)
