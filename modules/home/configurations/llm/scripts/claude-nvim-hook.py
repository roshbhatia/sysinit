#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "chromadb>=0.5.0",
# ]
# ///

import json
import sys
import os
import time
from pathlib import Path
import chromadb

def log_to_file(message, log_type="info"):
    log_dir = Path.home() / ".local/share/goose/logs/ai"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "claude-hooks.log"
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file, "a") as f:
        f.write(f"[{timestamp}] {log_type.upper()}: {message}\n")

def send_to_chromadb(data):
    try:
        # Initialize Chroma client with persistent storage
        chroma_client = chromadb.PersistentClient(path=str(Path.home() / "Documents/chromadb"))

        # Get or create collection
        collection_name = "claude_ai_interactions"
        collection = chroma_client.get_or_create_collection(
            name=collection_name,
            metadata={"description": "Claude AI interactions and context"}
        )

        if data.get("hook_event_name") in ["UserPromptSubmit", "PostToolUse"]:
            # Add data to collection
            collection.upsert(
                documents=[str(data)],
                ids=[f"{data.get('session_id', 'unknown')}_{int(time.time())}"],
                metadatas=[{
                    "event": data.get("hook_event_name"),
                    "session_id": data.get("session_id"),
                    "timestamp": int(time.time()),
                    "cwd": data.get("cwd", ""),
                    "tool_name": data.get("tool_name", "")
                }]
            )
            log_to_file(f"Added to ChromaDB: {data.get('hook_event_name')}")
            return True
    except Exception as e:
        log_to_file(f"ChromaDB integration error: {e}", "error")
        return False

def notify_ai_system(event_data):
    try:
        activity_log = Path.home() / ".local/share/goose/ai-activity.log"
        activity_log.parent.mkdir(parents=True, exist_ok=True)
        with open(activity_log, "a") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: {json.dumps(event_data)}\n")

        if event_data.get("tool_name") in ["Write", "Edit", "MultiEdit"]:
            if tool_input := event_data.get("tool_input"):
                if file_path := tool_input.get("file_path"):
                    marker_dir = Path.home() / ".local/share/goose/file_changes"
                    marker_dir.mkdir(parents=True, exist_ok=True)
                    marker_file = marker_dir / f"{int(time.time())}.marker"
                    with open(marker_file, "w") as f:
                        f.write(json.dumps({
                            "file": file_path,
                            "event": "claude_modified",
                            "session_id": event_data.get("session_id"),
                            "timestamp": int(time.time())
                        }))
    except Exception as e:
        log_to_file(f"AI system notification error: {e}", "error")

def handle_event(data):
    hook_event = data.get("hook_event_name")
    log_to_file(f"Hook event: {hook_event}")

    send_to_chromadb(data)
    notify_ai_system(data)

    if hook_event == "PreToolUse":
        tool_name = data.get("tool_name", "")
        safe_tools = ["Read", "Glob", "Grep", "WebFetch"]
        if tool_name in safe_tools:
            return {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "allow",
                    "permissionDecisionReason": "Auto-approved safe tool by AI system"
                },
                "suppressOutput": True
            }
    elif hook_event == "PostToolUse":
        tool_name = data.get("tool_name", "")
        tool_response = data.get("tool_response", {})
        if tool_name in ["Write", "Edit", "MultiEdit"] and tool_response.get("success"):
            return {
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "additionalContext": f"File successfully modified by {tool_name}. Changes logged to AI system."
                }
            }
    elif hook_event == "SessionStart":
        context_lines = [
            "🤖 Unified AI System Active",
            f"Session ID: {data.get('session_id', 'unknown')}",
            f"Working Directory: {data.get('cwd', 'unknown')}",
        ]
        try:
            # Initialize Chroma client to check if it's available
            chroma_client = chromadb.PersistentClient(path=str(Path.home() / "Documents/chromadb"))
            context_lines.append("✅ ChromaDB service active")
        except:
            context_lines.append("⚠️ ChromaDB service unavailable")

        return {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": "\n".join(context_lines)
            }
        }
    return {}

try:
    input_data = json.load(sys.stdin)
    result = handle_event(input_data)
    if result:
        print(json.dumps(result))
    sys.exit(0)
except Exception as e:
    log_to_file(f"Hook execution error: {e}", "error")
    sys.exit(1)
