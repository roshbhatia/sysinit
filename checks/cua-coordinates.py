import importlib.util
import sys
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("cua_macos", sys.argv[1])
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)

display = [1, 3840, 2160]
server = SimpleNamespace()
geometry = adapter.DisplayGeometry(server, lambda: tuple(display))


def blocked_click():
    try:
        geometry.prepare("computer_click")
    except RuntimeError as error:
        assert "computer_screenshot first" in str(error)
    else:
        raise AssertionError("Stale screenshot allowed a click")


blocked_click()
geometry.snapshot = geometry.prepare("computer_screenshot")
geometry.prepare("computer_click")
assert (640 * server._scale_x, 360 * server._scale_y) == (1920, 1080)

display[:] = [1, 2560, 1440]
blocked_click()
geometry.prepare("computer_press_key")
assert server._actual_width == 2560
geometry.snapshot = geometry.prepare("computer_screenshot")
geometry.prepare("computer_click")
assert (640 * server._scale_x, 360 * server._scale_y) == (1280, 720)

display[:] = [2, 2560, 1440]
blocked_click()
display[:] = [2, 1440, 2560]
geometry.snapshot = geometry.prepare("computer_screenshot")
assert (server._target_width, server._target_height) == (720, 1280)
display[:] = [2, 0, 0]
try:
    geometry.prepare("computer_press_key")
except RuntimeError:
    pass
else:
    raise AssertionError("Invalid display allowed an action")
print("CUA checks display geometry before actions and rejects stale coordinates")
