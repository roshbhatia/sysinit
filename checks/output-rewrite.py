import importlib.util
from pathlib import Path
import subprocess
import sys
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("rewrite", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
text = 'Basically, use `never change 42` and [source](https://example.com).\n```sh\necho "never change"\n```\n'
masked, values = module.protect(text)
assert module.restore(masked, values) == text
assert "echo" not in masked and "https://" not in masked
alert = {
    "Line": 1,
    "Span": [1, 11],
    "Match": "Basically, ",
    "Action": {"Name": "remove"},
}
assert module.deterministic(masked, [alert]).startswith("use ")
assert not module.valid("Do not change 42.", "Change 42.")
assert not module.valid("Keep 42.", "Keep 43.")
assert not module.valid("SYSINIT_KEEP_0_END", "Missing")
with (
    patch.object(module, "lint", return_value=[alert]),
    patch.object(
        module.subprocess, "run", side_effect=subprocess.TimeoutExpired("fm", 8)
    ) as run,
):
    result, status = module.rewrite(text, "style", "fm")
    assert '```sh\necho "never change"\n```' in result
    assert status == "deterministic-fallback" and run.call_count == 1
with (
    patch.object(module, "lint", return_value=[]),
    patch.object(module.subprocess, "run") as run,
):
    assert module.rewrite(text, "style", "fm") == (text, "clean")
    run.assert_not_called()
print(
    "Protected content, numeric/negation checks, clean bypass and one-pass fallback passed"
)
