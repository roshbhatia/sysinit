import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


review = load("review", sys.argv.pop(1))
terminal = load("terminal", sys.argv.pop(1))
functions = Path(sys.argv.pop(1))


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Test",
            "GIT_AUTHOR_EMAIL": "test@example.invalid",
            "GIT_COMMITTER_NAME": "Test",
            "GIT_COMMITTER_EMAIL": "test@example.invalid",
            "GH_CALLS": str(self.root / "gh-calls"),
        }
        self.patcher = patch.dict(os.environ, self.env)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def executable(self, name, body):
        target = self.bin / name
        target.write_text(f"#!{sys.executable}\n" + body)
        target.chmod(0o755)

    def git(self, directory, *args):
        return subprocess.check_output(
            ["git", "-C", str(directory), *args], text=True
        ).strip()

    def test_review_compares_pr_merge_base_and_preserves_notes(self):
        source, target = self.root / "source", self.root / "review"
        source.mkdir()
        target.mkdir()
        self.git(source, "init", "--quiet", "--template=")
        (source / "base.txt").write_text("base\n")
        self.git(source, "add", ".")
        self.git(source, "commit", "--quiet", "-m", "base")
        base = self.git(source, "rev-parse", "HEAD")
        for text in ["first\n", "second\n"]:
            (source / "change.txt").write_text(text)
            self.git(source, "add", ".")
            self.git(source, "commit", "--quiet", "-m", "PR change")
        head = self.git(source, "rev-parse", "HEAD")
        self.executable(
            "changes",
            "import json, subprocess\nfrom pathlib import Path\nPath('observed.json').write_text(json.dumps({'files': subprocess.check_output(['git', 'diff', '--cached', '--name-only'], text=True), 'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()}))\n",
        )
        self.executable(
            "nvim",
            "import json, sys\nfrom pathlib import Path\nPath('editor.json').write_text(json.dumps(sys.argv[1:]))\n",
        )
        self.assertEqual(
            review.review(target, source.as_uri(), base, head, "changes", False), 0
        )
        observed = json.loads((target / "observed.json").read_text())
        self.assertEqual(observed, {"files": "change.txt\n", "head": base})
        self.git(target, "notes", "add", "-m", "Keep this review note", head)
        self.assertEqual(
            review.review(target, source.as_uri(), base, head, "nvim", True), 0
        )
        self.assertEqual(self.git(target, "rev-list", "--count", head), "3")
        self.assertEqual(
            self.git(target, "notes", "show", head), "Keep this review note"
        )
        self.assertIn(
            f"DiffviewFileHistory --range={base}..{head}",
            json.loads((target / "editor.json").read_text()),
        )
        self.assertEqual(self.git(source, "status", "--porcelain"), "")

    def test_invalid_url_cannot_fetch(self):
        with patch.object(review, "read_json") as api:
            for url in [
                "https://github.com/o/r/issues/1",
                "https://github.com/o/../pull/1",
                "https://github.com/o/r/pull/1;echo",
            ]:
                with self.assertRaises(ValueError):
                    review.main(url)
            api.assert_not_called()

    def test_provider_preserves_protocol_and_explicit_model(self):
        request = {
            "prompt": "Extract URLs",
            "input": "data",
            "model": "opus",
            "schema": {"type": "object"},
        }
        result = terminal.prepare(
            {"action": "inference.generate", "request": request.copy()}
        )["request"]
        self.assertIn("terminal pipeline", result["prompt"])
        for field in ["input", "model", "schema"]:
            self.assertEqual(result[field], request[field])
        envelope = {"action": "models.list", "request": {}}
        self.assertEqual(terminal.prepare(envelope.copy()), envelope)

    def queue(self, output, message, dry=False, ask_exit=0):
        self.executable("ask", f"import sys\nprint({output!r})\nsys.exit({ask_exit})\n")
        self.executable(
            "gh",
            "import json, os, sys\nwith open(os.environ['GH_CALLS'], 'a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')\n",
        )
        command = f'use "{functions}" *; {json.dumps(message)} | prq' + (
            " --dry-run | to json --raw" if dry else ""
        )
        return subprocess.run(
            ["nu", "--no-config-file", "-c", command], capture_output=True, text=True
        )

    def test_queue_deduplicates_without_shell_evaluation(self):
        urls = [
            "https://github.com/one/repo/pull/1",
            "https://github.com/two/repo/pull/22",
        ]
        message = "<github.com/one/repo/pull/1|link>\nhttps://github.com/two/repo/pull/22/files?x=y"
        result = self.queue(json.dumps({"urls": urls + urls[:1]}), message)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = [
            json.loads(line)
            for line in (self.root / "gh-calls").read_text().splitlines()
        ]
        self.assertEqual(calls, [["dash", url] for url in urls])

    def test_invalid_queue_never_opens_any_pr(self):
        valid = "https://github.com/one/repo/pull/1"
        for response, code in [
            (json.dumps({"urls": [valid, "https://github.com/other/repo/pull/2"]}), 0),
            ("not JSON", 0),
            ('{"urls":[]}', 1),
        ]:
            result = self.queue(response, valid, ask_exit=code)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((self.root / "gh-calls").exists())

    def test_dry_run_and_empty_results_do_not_launch(self):
        url = "https://github.com/one/repo/pull/1"
        result = self.queue(json.dumps({"urls": [url]}), url, dry=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [url])
        self.assertFalse((self.root / "gh-calls").exists())
        result = self.queue('{"urls":[]}', "No pull requests here")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / "gh-calls").exists())


unittest.main()
