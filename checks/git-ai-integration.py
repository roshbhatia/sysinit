import json
import datetime
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time


def main():
    ai, gate, provider = map(os.path.abspath, sys.argv[1:4])
    git = shutil.which("git")
    with tempfile.TemporaryDirectory(prefix="gitai-", dir="/tmp") as temporary:
        root = pathlib.Path(temporary)
        home, repo = root / "home", root / "repo"
        home.mkdir()
        repo.mkdir()
        env = {
            **os.environ,
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "XDG_DATA_HOME": str(home / ".local/share"),
            "GIT_CONFIG_GLOBAL": str(home / ".gitconfig"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AI_DAEMON_HOME": str(home),
            "CODEX_HOME": str(home / ".codex"),
        }
        (home / ".git-ai").mkdir()
        (home / ".git-ai/config.json").write_text(
            json.dumps(
                {
                    "git_path": git,
                    "prompt_storage": "local",
                    "telemetry_oss": "off",
                    "disable_auto_updates": True,
                    "disable_version_checks": True,
                    "feature_flags": {
                        "transcript_sweep": False,
                        "daemon_log_upload": False,
                        "token_usage_metrics": False,
                    },
                }
            )
        )

        def run(*args, data=None, check=True):
            result = subprocess.run(
                args,
                cwd=repo,
                env=env,
                input=data,
                text=True,
                capture_output=True,
                check=False,
                timeout=60,
            )
            if check and result.returncode:
                raise RuntimeError(f"{args}: {result.stdout}\n{result.stderr}")
            return result

        run(
            git,
            "config",
            "--global",
            "trace2.eventTarget",
            "af_unix:stream:" + str(home / ".git-ai/internal/daemon/trace2.sock"),
        )
        run(git, "config", "--global", "trace2.eventNesting", "0")
        with (root / "daemon.log").open("w") as log:
            daemon = subprocess.Popen(
                [ai, "bg", "run"], cwd=repo, env=env, stdout=log, stderr=log
            )
            try:
                for _ in range(60):
                    if run(ai, "bg", "status", check=False).returncode == 0:
                        break
                    if daemon.poll() is not None:
                        raise RuntimeError((root / "daemon.log").read_text())
                    time.sleep(0.25)
                else:
                    raise RuntimeError("Git AI daemon did not become ready")
                run(git, "init", "--quiet")
                run(git, "config", "user.name", "Integration test")
                run(git, "config", "user.email", "test@example.invalid")
                sample = repo / "sample.txt"
                sample.write_text("baseline\n")
                run(git, "add", ".")
                run(git, "commit", "-m", "baseline")
                sample.write_text("baseline\nhuman line\n")
                payload = {
                    "cwd": str(repo),
                    "session_id": "native-codex-test",
                    "model": "test-model",
                    "tool_name": "functions.apply_patch",
                    "tool_use_id": "call-1",
                    "tool_input": "*** Begin Patch\n*** Update File: sample.txt\n@@\n human line\n+agent line\n*** End Patch",
                    "tool_response": "Success. Updated the following files:\nM sample.txt",
                }

                def checkpoint(event):
                    payload["hook_event_name"] = event
                    request = {
                        "requestId": "fixture",
                        "input": {
                            "event": {
                                "harness": "codex",
                                "cwd": str(repo),
                                "raw": payload,
                            }
                        },
                    }
                    result = json.loads(
                        run(gate, "serve", data=json.dumps(request)).stdout
                    )
                    assert result["output"]["decision"] == "pass", result

                checkpoint("PreToolUse")
                sample.write_text("baseline\nhuman line\nagent line\n")
                checkpoint("PostToolUse")
                run(git, "add", ".")
                run(git, "commit", "-m", "mixed human and agent edit")
                run(ai, "await", "--timeout", "30")
                blame = json.loads(run(ai, "blame", "--json", "sample.txt").stdout)
                assert list(blame["lines"]) == ["3"], blame
                agent = blame["prompts"][blame["lines"]["3"]]["agent_id"]
                assert agent == {
                    "tool": "codex",
                    "id": "native-codex-test",
                    "model": "test-model",
                }, agent
                run(git, "notes", "--ref=changes", "add", "-m", "review stays separate")
                before = run(git, "rev-parse", "refs/notes/changes").stdout
                request = {
                    "version": "changes.provider/v1",
                    "action": "changes.notes",
                    "directory": str(repo),
                    "files": ["sample.txt"],
                    "from": "HEAD~1",
                    "to": "HEAD",
                }
                notes = json.loads(
                    run(sys.executable, provider, data=json.dumps(request)).stdout
                )["notes"]
                assert len(notes) == 1 and notes[0]["anchor"]["line"] == 3, notes
                assert notes[0]["session"] == "native-codex-test", notes
                assert (
                    "traces --all --session native-codex-test" in notes[0]["rationale"]
                ), notes
                assert run(git, "rev-parse", "refs/notes/changes").stdout == before
                manifests = home / ".config/changes/providers/git-ai"
                manifests.mkdir(parents=True)
                (manifests / "provider.yaml").write_text(
                    json.dumps(
                        {
                            "version": "provider/v1",
                            "name": "git-ai",
                            "description": "Read Git AI attribution",
                            "command": [sys.executable, provider],
                            "actions": {
                                "changes.notes": {"description": "Read attribution"}
                            },
                        }
                    )
                )
                env["CHANGES_PROVIDERS_DIRECTORY"] = str(manifests.parent)
                listed = json.loads(
                    run(
                        "changes",
                        "note",
                        "list",
                        "--commit",
                        "HEAD",
                        "--provider",
                        "git-ai",
                        "--json",
                    ).stdout
                )
                assert "native-codex-test" in json.dumps(listed), listed
                sample.write_text("baseline\nhuman line\nagent line\nhuman suffix\n")
                for arguments in [[], ["--staged"]]:
                    if arguments:
                        run(git, "add", "sample.txt")
                    listed = json.loads(
                        run(
                            "changes",
                            "note",
                            "list",
                            "--provider",
                            "git-ai",
                            "--json",
                            *arguments,
                        ).stdout
                    )
                    assert len(listed["notes"]) == 1, listed
                    assert listed["notes"][0]["anchor"]["line"] == 3, listed
                timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
                sessions = home / ".codex/sessions"
                sessions.mkdir(parents=True)
                events = [
                    {
                        "type": "session_meta",
                        "timestamp": timestamp,
                        "payload": {"id": agent["id"], "cwd": str(repo)},
                    },
                    {
                        "type": "event_msg",
                        "timestamp": timestamp,
                        "payload": {
                            "type": "item_completed",
                            "thread_id": agent["id"],
                            "turn_id": "fixture-turn",
                            "item": {
                                "type": "AgentMessage",
                                "id": "fixture-message",
                                "content": [
                                    {
                                        "type": "Text",
                                        "text": "Native attribution fixture",
                                    }
                                ],
                            },
                        },
                    },
                ]
                (sessions / "rollout-native-codex-test.jsonl").write_text(
                    "\n".join(json.dumps(event) for event in events) + "\n"
                )
                traces_manifest = home / ".config/traces/providers/codex"
                traces_manifest.mkdir(parents=True)
                (traces_manifest / "provider.yaml").write_text(
                    json.dumps(
                        {
                            "version": "provider/v1",
                            "name": "codex",
                            "description": "Read Codex sessions",
                            "command": [shutil.which("traces-provider-codex")],
                            "actions": {
                                "activity.read": {
                                    "description": "Read session activity",
                                    "argv": [
                                        "--since",
                                        "{{ .Since }}",
                                        "--session",
                                        "{{ .Session }}",
                                        "--directory",
                                        "{{ .Directory }}",
                                    ],
                                }
                            },
                        }
                    )
                )
                traced = run(
                    "traces",
                    "--provider",
                    "codex",
                    "--all",
                    "--session",
                    agent["id"],
                    "--once",
                    "--view",
                    "output",
                    "--format",
                    "jsonl",
                ).stdout
                assert "Native attribution fixture" in traced, traced
                bad = {"requestId": "bad", "input": {"event": {"harness": "codex"}}}
                failed = run(gate, "serve", data=json.dumps(bad), check=False)
                assert (
                    failed.returncode != 0
                    and "missing native hook payload" in failed.stderr
                )
                failed = run(
                    ai,
                    "checkpoint",
                    "codex",
                    "--hook-input",
                    "stdin",
                    data="{}",
                    check=False,
                )
                assert failed.returncode != 0 and "preset error" in failed.stderr, (
                    failed
                )
                print(
                    "Native checkpoints preserve human edits; Git notes and Traces session provenance compose"
                )
            finally:
                daemon.terminate()
                try:
                    daemon.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    daemon.kill()
                    daemon.wait()


if __name__ == "__main__":
    main()
