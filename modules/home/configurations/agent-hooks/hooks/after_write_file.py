#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pynvim>=0.5.0",
#     "psutil>=5.9.0",
# ]
# ///
"""After write file hook - reloads buffer and enables diff mode after agent writes."""

import sys
import os

# Add lib directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "lib"))

from nvim_client import create_client
from config import load_config, is_enabled_for_agent
from logger import create_logger
from hook_handlers import HookHandlers


def detect_agent_type():
    """Detect which agent is calling this hook."""
    try:
        sys.path.insert(
            0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "agents")
        )

        from cursor.adapter import detect_agent as detect_cursor

        if detect_cursor():
            return "cursor"

        from claude.adapter import detect_agent as detect_claude

        if detect_claude():
            return "claude"

        from opencode.adapter import detect_agent as detect_opencode

        if detect_opencode():
            return "opencode"
    except ImportError:
        pass

    return "unknown"


def main():
    """Main hook entry point."""
    # Load configuration
    config = load_config()
    logger = create_logger(debug=config.debug, hook_name="after_write_file")

    try:
        # Detect agent type
        agent_type = detect_agent_type()
        logger.debug(f"Detected agent: {agent_type}")

        # Check if enabled for this agent
        if not is_enabled_for_agent(config, agent_type):
            logger.info(f"Hook disabled for agent: {agent_type}")
            sys.exit(0)

        # Import appropriate adapter
        if agent_type == "cursor":
            from cursor.adapter import parse_after_write_file, format_output
        elif agent_type == "claude":
            from claude.adapter import parse_after_write_file, format_output
        elif agent_type == "opencode":
            from opencode.adapter import parse_after_write_file, format_output
        else:
            # Generic fallback
            file_path = sys.argv[1] if len(sys.argv) > 1 else None
            if not file_path:
                logger.error("No file path provided")
                sys.exit(0)

            def format_output(result):
                return str(result)

        # Parse input
        if agent_type != "unknown":
            file_path = parse_after_write_file()
        else:
            file_path = sys.argv[1] if len(sys.argv) > 1 else None

        if not file_path:
            logger.error("No file path provided")
            sys.exit(0)

        # Create Neovim client and handlers
        nvim = create_client(socket_path=config.socket_path, logger=logger)
        handlers = HookHandlers(nvim, config, logger)

        # Execute hook
        result = handlers.after_write_file(file_path)

        # Output result
        output = format_output(result) if agent_type != "unknown" else str(result)
        print(output)

        # Disconnect
        nvim.disconnect()

        # Always exit 0 (don't block agent operations)
        sys.exit(0)

    except Exception as e:
        logger.exception("Unexpected error in hook", e)
        sys.exit(0)


if __name__ == "__main__":
    main()
