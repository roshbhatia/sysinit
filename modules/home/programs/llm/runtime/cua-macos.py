"""Adapt CUA 0.3.42 screenshot coordinates to macOS display points."""

import asyncio
from importlib.metadata import version

COORDINATE_TOOLS = {
    "computer_click",
    "computer_double_click",
    "computer_move",
    "computer_drag",
    "computer_scroll",
    "computer_mouse_down",
}


class DisplayGeometry:
    def __init__(self, server, read_display):
        self.server = server
        self.read_display = read_display
        self.snapshot = None

    def prepare(self, name):
        display = self.read_display()
        _, width, height = display
        if width <= 0 or height <= 0:
            raise RuntimeError("CUA cannot determine the main display geometry")
        if name in COORDINATE_TOOLS and display != self.snapshot:
            raise RuntimeError(
                "Display changed or no screenshot exists; call computer_screenshot first"
            )
        ratio = min(1, 1280 / max(width, height))
        self.server._actual_width = width
        self.server._actual_height = height
        self.server._target_width = int(width * ratio)
        self.server._target_height = int(height * ratio)
        self.server._scale_x = width / self.server._target_width
        self.server._scale_y = height / self.server._target_height
        return display


def main():
    import Quartz
    from computer_server import mcp_server
    from computer_server.cli import main as run_server
    from computer_server.main import mcp_server as server
    from fastmcp.exceptions import ToolError
    from fastmcp.server.middleware import Middleware

    if version("cua-computer-server") != "0.3.42":
        raise RuntimeError("Review the CUA macOS coordinate adapter before upgrading")

    def read_display():
        display_id = Quartz.CGMainDisplayID()
        bounds = Quartz.CGDisplayBounds(display_id)
        return display_id, int(bounds.size.width), int(bounds.size.height)

    geometry = DisplayGeometry(mcp_server, read_display)

    class CheckDisplay(Middleware):
        def __init__(self):
            self.lock = asyncio.Lock()

        async def on_call_tool(self, context, call_next):
            async with self.lock:
                name = context.message.name
                try:
                    display = geometry.prepare(name)
                except RuntimeError as error:
                    raise ToolError(str(error)) from error
                if (
                    name == "computer_screenshot"
                    and not Quartz.CGPreflightScreenCaptureAccess()
                ):
                    raise ToolError(
                        "Allow Screen Recording for ~/.local/state/sysinit/signed/bin/cua-uv "
                        "in macOS Privacy & Security, then restart the CUA LaunchAgent"
                    )
                result = await call_next(context)
                if name == "computer_screenshot":
                    geometry.snapshot = display
                return result

    server.add_middleware(CheckDisplay())
    run_server()


if __name__ == "__main__":
    main()
