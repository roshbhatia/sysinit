import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


NU, MODULE = sys.argv[1:3]
sys.argv = sys.argv[:1]

MOCK = r"""#!__PYTHON__
import json, os, sys
from pathlib import Path
name, args = Path(sys.argv[0]).name, sys.argv[1:]
with open(os.environ["EXTERN_ARGV"], "a") as log:
    log.write(json.dumps([name, *args]) + "\n")
if os.environ.get("EXTERN_FAIL"):
    print("extern fixture failure", file=sys.stderr)
    sys.exit(7)
if os.environ.get("EXTERN_BAD_JSON"):
    print("invalid JSON")
elif os.environ.get("EXTERN_EMPTY"):
    pass
elif any(arg in args for arg in ["--json", "--format", "--format-version", "-o"]) or "inspect" in args:
    print(os.environ["EXTERN_DATA"])
else:
    print("native text")
"""

CASES = [
    (
        "gh pr list --limit 2",
        [
            "gh",
            "pr",
            "list",
            "--json",
            "number,title,url,state,isDraft,author,headRefName,baseRefName,updatedAt",
        ],
        "array",
    ),
    (
        "gh issue list --state open",
        [
            "gh",
            "issue",
            "list",
            "--json",
            "number,title,url,state,author,assignees,labels,updatedAt",
        ],
        "array",
    ),
    (
        "gh run list --limit 2",
        [
            "gh",
            "run",
            "list",
            "--json",
            "databaseId,workflowName,headBranch,status,conclusion,url,createdAt",
        ],
        "array",
    ),
    ("docker ps --all", ["docker", "container", "ls", "--format"], "objects"),
    ("docker images", ["docker", "image", "ls", "--format"], "objects"),
    ("docker container ls", ["docker", "container", "ls", "--format"], "objects"),
    ("docker image ls", ["docker", "image", "ls", "--format"], "objects"),
    ("docker inspect example", ["docker", "inspect", "example"], "array"),
    ("docker context ls", ["docker", "context", "ls", "--format"], "objects"),
    ("nix flake metadata .", ["nix", "flake", "metadata", "--json"], "record"),
    ("nix flake show .", ["nix", "flake", "show", "--json"], "record"),
    ("nix path-info ./result", ["nix", "path-info", "--json"], "record"),
    ("kubectl get pods", ["kubectl", "get", "-o", "json", "pods"], "record"),
    ("kubecolor get pods", ["kubecolor", "get", "-o", "json", "pods"], "record"),
    ("k get pods", ["k", "get", "-o", "json", "pods"], "record"),
    ("kubectl config view", ["kubectl", "config", "view", "-o", "json"], "record"),
    ("uv pip list", ["uv", "pip", "list", "--format", "json"], "array"),
    (
        "cargo metadata --no-deps",
        ["cargo", "metadata", "--format-version", "1"],
        "record",
    ),
    ("pueue status status=running", ["pueue", "status", "--json"], "record"),
    ("colima list", ["colima", "list", "--json"], "objects"),
]


class ExternTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.argv = self.root / "argv.jsonl"
        self.env = os.environ | {
            "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
            "EXTERN_ARGV": str(self.argv),
            "EXTERN_DATA": '{"name":"fixture"}',
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Fixture Author",
            "GIT_COMMITTER_NAME": "Fixture Author",
            "GIT_AUTHOR_EMAIL": "fixture@example.invalid",
            "GIT_COMMITTER_EMAIL": "fixture@example.invalid",
        }
        for name in {case[1][0] for case in CASES}:
            executable = self.bin / name
            executable.write_text(MOCK.replace("__PYTHON__", sys.executable))
            executable.chmod(0o755)

    def nu(self, code, *, env=None, check=True):
        result = subprocess.run(
            [NU, "--no-config-file", "-c", f"use {json.dumps(MODULE)} *; {code}"],
            cwd=self.root,
            env=self.env | (env or {}),
            text=True,
            capture_output=True,
            timeout=20,
        )
        if check:
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, "")
        return result

    def git(self, *args):
        return subprocess.run(
            [shutil.which("git"), *args],
            cwd=self.root,
            env=self.env,
            check=True,
            capture_output=True,
            text=True,
        ).stdout

    def init_repo(self):
        self.git("init", "--initial-branch=main")
        (self.root / "original file").write_text("original\n")
        (self.root / "tracked").write_text("first\n")
        self.git("add", ".")
        self.git("commit", "-m", 'subject | with "quotes"')
        (self.root / "tracked").write_text("second\n")
        self.git("add", "tracked")
        self.git("commit", "--allow-empty-message", "-m", "")

    def test_cli_arguments_and_structured_output(self):
        for command, prefix, kind in CASES:
            with self.subTest(command=command):
                expected = {"name": "fixture"}
                data = json.dumps(expected)
                if kind == "array":
                    expected = [expected]
                    data = json.dumps(expected)
                elif kind == "objects":
                    expected = [expected, {"name": "second"}]
                    data = "\n".join(json.dumps(row) for row in expected)
                result = self.nu(
                    f"{command} | collect | to json --raw", env={"EXTERN_DATA": data}
                )
                self.assertEqual(json.loads(result.stdout), expected)
                argv = json.loads(self.argv.read_text().splitlines()[-1])
                self.assertEqual(argv[: len(prefix)], prefix)

    def test_native_output_and_caret_escape(self):
        for code in [
            "gh pr list",
            "gh pr list | print",
            "gh pr list | ^cat",
            "^gh pr list | str trim",
        ]:
            with self.subTest(code=code):
                self.assertEqual(self.nu(code).stdout.strip(), "native text")
                self.assertEqual(
                    json.loads(self.argv.read_text().splitlines()[-1]),
                    ["gh", "pr", "list"],
                )
        result = json.loads(self.nu("gh pr list | complete | to json --raw").stdout)
        self.assertEqual(result["stdout"], "native text\n")
        self.nu("gh pr list o> native.txt")
        self.assertEqual((self.root / "native.txt").read_text(), "native text\n")
        result = self.nu("gh --repo fixture/repo pr list | collect | to json --raw")
        self.assertEqual(json.loads(result.stdout), "native text")

    def test_variable_capture_and_flags(self):
        result = self.nu("let runs = gh run list --limit 3; $runs.name | to json --raw")
        self.assertEqual(json.loads(result.stdout), "fixture")
        self.assertEqual(
            json.loads(self.argv.read_text().splitlines()[-1])[-2:], ["--limit", "3"]
        )
        result = self.nu("gh run list --limit invalid | collect", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("int", result.stderr)

    def test_external_failures_and_invalid_json(self):
        for env in [{"EXTERN_FAIL": "1"}, {"EXTERN_BAD_JSON": "1"}]:
            with self.subTest(env=env):
                result = self.nu("gh pr list | collect", env=env, check=False)
                self.assertNotEqual(result.returncode, 0)
        result = self.nu(
            "docker ps | collect | to json --raw", env={"EXTERN_EMPTY": "1"}
        )
        self.assertEqual(json.loads(result.stdout), [])
        result = self.nu("docker ps | collect", env={"EXTERN_FAIL": "1"}, check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_git_status_paths_and_renames(self):
        self.init_repo()
        clean = self.nu("git status | collect | to json --raw")
        self.assertEqual(json.loads(clean.stdout), [])
        target = 'renamed "file"\nsecond line'
        self.git("mv", "original file", target)
        (self.root / "tracked").write_text("modified\n")
        (self.root / 'new "file"').write_text("new\n")
        rows = json.loads(self.nu("git status | collect | to json --raw").stdout)
        by_file = {row["file"]: row for row in rows}
        self.assertEqual(
            by_file[target],
            {"status": "R ", "file": target, "original_file": "original file"},
        )
        self.assertEqual(by_file["tracked"]["status"], " M")
        self.assertEqual(by_file['new "file"']["status"], "??")
        result = self.nu("git status --branch | collect | to json --raw")
        self.assertEqual(json.loads(result.stdout), rows)
        result = self.nu("git status -- tracked | collect | to json --raw")
        self.assertEqual(
            [row["file"] for row in json.loads(result.stdout)], ["tracked"]
        )
        filename = json.dumps('new "file"')
        result = self.nu(f"git add --dry-run {filename} | complete | to json --raw")
        self.assertEqual(json.loads(result.stdout)["exit_code"], 0)
        self.assertIn('new "file"', json.loads(result.stdout)["stdout"])
        self.assertEqual(
            self.git("diff", "--cached", "--name-only", "-z"), target + "\0"
        )

    def test_git_failure_is_not_an_empty_table(self):
        for command in ["git status", "git log"]:
            with self.subTest(command=command):
                result = self.nu(f"{command} | collect", check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("not a git repository", result.stderr)

    def test_git_log_delimiters_empty_subject_and_empty_result(self):
        self.init_repo()
        rows = json.loads(self.nu("git log -n 2 | collect | to json --raw").stdout)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["subject"], "")
        self.assertEqual(rows[1]["subject"], 'subject | with "quotes"')
        self.assertEqual(rows[0]["author"], "Fixture Author")
        self.assertEqual(len(rows[0]["hash"]), 40)
        self.assertIsInstance(rows[0]["date"], str)
        result = self.nu(
            "git log --grep absent-fixture-subject | collect | to json --raw"
        )
        self.assertEqual(json.loads(result.stdout), [])
        result = self.nu("git log --oneline -n 1 | complete | to json --raw")
        self.assertEqual(
            json.loads(result.stdout)["stdout"], self.git("log", "--oneline", "-n", "1")
        )

    def test_completion_preserves_native_signatures(self):
        self.init_repo()
        self.git("branch", "fixture-branch")
        result = self.nu("'git switch fixture-' | commandline complete | to json --raw")
        self.assertIn("fixture-branch", result.stdout)
        result = self.nu("'gh pr list --lim' | commandline complete | to json --raw")
        self.assertIn("--limit", result.stdout)

    def test_completion_keeps_dynamic_external_completer(self):
        code = """
          $env.config.completions.external.enable = true
          $env.config.completions.external.completer = {|place|
            if $place.command == ['kubectl get' 'fixture-'] { ['fixture-pod'] } else { [] }
          }
          'kubectl get fixture-' | commandline complete | to json --raw
        """
        self.assertIn("fixture-pod", self.nu(code).stdout)


unittest.main()
