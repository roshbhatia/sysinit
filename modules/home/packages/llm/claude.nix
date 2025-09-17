{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  claudeEnabled = values.llm.claude.enabled;

  claudeYarnPackages = [
    "@anthropic-ai/claude-code"
    "@owloops/claude-powerline"
  ]
  ++ values.llm.claude.yarnPackages;

  claudeUvPackages = [
    "SuperClaude"
    "chromadb"
    "requests"
  ]
  ++ values.llm.claude.uvPackages;

  # Claude Code hook script for AI system integration
  claudeHookScript = pkgs.writeShellScript "claude-ai-hook" ''
    #!/usr/bin/env python3
    """
    Claude Code Hook for Unified AI System Integration
    Integrates with the sysinit AI system for enhanced workflow automation
    """

    import json
    import sys
    import os
    import subprocess
    import time
    from pathlib import Path
    from typing import Dict, Any, Optional

    def log_to_file(message: str, log_type: str = "info"):
        """Log messages to the AI system log"""
        log_dir = Path.home() / ".local/share/goose/logs/ai"
        log_dir.mkdir(parents=True, exist_ok=True)

        log_file = log_dir / "claude-hooks.log"
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

        with open(log_file, "a") as f:
            f.write(f"[{timestamp}] {log_type.upper()}: {message}\n")

    def send_to_chromadb(data: Dict[str, Any]) -> bool:
        """Send data to local ChromaDB for vectorization"""
        try:
            import requests

            # Check if ChromaDB is running
            try:
                response = requests.get("http://localhost:8000/api/v1/version", timeout=2)
                if response.status_code != 200:
                    log_to_file("ChromaDB not accessible", "warn")
                    return False
            except requests.exceptions.RequestException:
                log_to_file("ChromaDB service not running", "warn")
                return False

            # Prepare data for ChromaDB
            collection_name = "claude_ai_interactions"

            # Create or get collection
            collection_data = {
                "name": collection_name,
                "metadata": {"description": "Claude AI interactions and context"}
            }

            requests.post("http://localhost:8000/api/v1/collections",
                         json=collection_data, timeout=5)

            # Add document to collection
            if data.get("hook_event_name") in ["UserPromptSubmit", "PostToolUse"]:
                doc_data = {
                    "documents": [str(data)],
                    "ids": [f"{data.get('session_id', 'unknown')}_{int(time.time())}"],
                    "metadatas": [{
                        "event": data.get("hook_event_name"),
                        "session_id": data.get("session_id"),
                        "timestamp": int(time.time()),
                        "cwd": data.get("cwd", ""),
                        "tool_name": data.get("tool_name", "")
                    }]
                }

                response = requests.post(
                    f"http://localhost:8000/api/v1/collections/{collection_name}/add",
                    json=doc_data,
                    timeout=10
                )

                if response.status_code == 200:
                    log_to_file(f"Added to ChromaDB: {data.get('hook_event_name')}")
                    return True
                else:
                    log_to_file(f"ChromaDB add failed: {response.text}", "error")

        except Exception as e:
            log_to_file(f"ChromaDB integration error: {e}", "error")

        return False

    def notify_ai_system(event_data: Dict[str, Any]) -> None:
        """Notify the sysinit AI system about the event"""
        try:
            # Write to AI activity log
            activity_log = Path.home() / ".local/share/goose/ai-activity.log"
            activity_log.parent.mkdir(parents=True, exist_ok=True)

            with open(activity_log, "a") as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: {json.dumps(event_data)}\n")

            # If this is a file modification, trigger file watcher
            if event_data.get("tool_name") in ["Write", "Edit", "MultiEdit"]:
                if tool_input := event_data.get("tool_input"):
                    if file_path := tool_input.get("file_path"):
                        # Touch a marker file to trigger our AI file watcher
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

    def handle_pre_tool_use(data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle PreToolUse hook events"""
        tool_name = data.get("tool_name", "")

        # Log the tool usage
        log_to_file(f"Pre-tool: {tool_name}")

        # Send to ChromaDB for context building
        send_to_chromadb(data)

        # Auto-approve certain safe tools
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

        # For file operations, add extra logging
        if tool_name in ["Write", "Edit", "MultiEdit"]:
            notify_ai_system(data)

        return {}

    def handle_post_tool_use(data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle PostToolUse hook events"""
        tool_name = data.get("tool_name", "")
        tool_response = data.get("tool_response", {})

        log_to_file(f"Post-tool: {tool_name} - Success: {tool_response.get('success', False)}")

        # Send to ChromaDB
        send_to_chromadb(data)

        # Notify AI system
        notify_ai_system(data)

        # If file was modified successfully, add context
        if tool_name in ["Write", "Edit", "MultiEdit"] and tool_response.get("success"):
            return {
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "additionalContext": f"File successfully modified by {tool_name}. Changes logged to AI system."
                }
            }

        return {}

    def handle_user_prompt_submit(data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle UserPromptSubmit hook events"""
        prompt = data.get("prompt", "")

        log_to_file(f"User prompt: {prompt[:100]}...")

        # Send to ChromaDB for context
        send_to_chromadb(data)

        # Add AI system context
        ai_context = []

        # Check for recent AI activity
        activity_log = Path.home() / ".local/share/goose/ai-activity.log"
        if activity_log.exists():
            try:
                with open(activity_log, "r") as f:
                    lines = f.readlines()[-5:]  # Last 5 entries
                    if lines:
                        ai_context.append("Recent AI activity:")
                        for line in lines:
                            ai_context.append(f"  {line.strip()}")
            except Exception:
                pass

        if ai_context:
            return {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": "\n".join(ai_context)
                }
            }

        return {}

    def handle_session_start(data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle SessionStart hook events"""
        log_to_file("Claude session started")

        # Initialize AI system context
        context_lines = [
            "🤖 Unified AI System Active",
            f"Session ID: {data.get('session_id', 'unknown')}",
            f"Working Directory: {data.get('cwd', 'unknown')}",
        ]

        # Check AI system status
        try:
            status_file = Path.home() / ".local/share/goose/system_status.json"
            if status_file.exists():
                with open(status_file, "r") as f:
                    status = json.load(f)
                    active_providers = [name for name, info in status.get("providers", {}).items()
                                      if info.get("connected", False)]
                    if active_providers:
                        context_lines.append(f"Active AI Providers: {', '.join(active_providers)}")
        except Exception:
            pass

        # Check ChromaDB status
        try:
            import requests
            response = requests.get("http://localhost:8000/api/v1/version", timeout=2)
            if response.status_code == 200:
                context_lines.append("✅ ChromaDB service active")
            else:
                context_lines.append("⚠️ ChromaDB service unavailable")
        except:
            context_lines.append("⚠️ ChromaDB service unavailable")

        return {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": "\n".join(context_lines)
            }
        }

    def main():
        """Main hook handler"""
        try:
            # Read input from stdin
            input_data = json.load(sys.stdin)

            hook_event = input_data.get("hook_event_name")

            # Route to appropriate handler
            if hook_event == "PreToolUse":
                result = handle_pre_tool_use(input_data)
            elif hook_event == "PostToolUse":
                result = handle_post_tool_use(input_data)
            elif hook_event == "UserPromptSubmit":
                result = handle_user_prompt_submit(input_data)
            elif hook_event == "SessionStart":
                result = handle_session_start(input_data)
            else:
                log_to_file(f"Unhandled hook event: {hook_event}")
                result = {}

            # Output result
            if result:
                print(json.dumps(result))

            # Exit with success
            sys.exit(0)

        except json.JSONDecodeError as e:
            log_to_file(f"JSON decode error: {e}", "error")
            sys.exit(1)
        except Exception as e:
            log_to_file(f"Hook execution error: {e}", "error")
            sys.exit(1)

    if __name__ == "__main__":
        main()
  '';

  # Claude settings with hooks configuration
  claudeSettings = pkgs.writeText "claude-settings.json" (builtins.toJSON {
    hooks = {
      PreToolUse = [
        {
          matcher = "*";
          hooks = [
            {
              type = "command";
              command = "${pkgs.python3}/bin/python3 ${claudeHookScript}";
              timeout = 30000;
            }
          ];
        }
      ];
      PostToolUse = [
        {
          matcher = "Write|Edit|MultiEdit";
          hooks = [
            {
              type = "command";
              command = "${pkgs.python3}/bin/python3 ${claudeHookScript}";
              timeout = 30000;
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "${pkgs.python3}/bin/python3 ${claudeHookScript}";
              timeout = 10000;
            }
          ];
        }
      ];
      SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "${pkgs.python3}/bin/python3 ${claudeHookScript}";
              timeout = 10000;
            }
          ];
        }
      ];
    };
  });

  # ChromaDB launchd service configuration
  chromadbPlist = pkgs.writeText "com.sysinit.chromadb.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.sysinit.chromadb</string>
        <key>ProgramArguments</key>
        <array>
            <string>${pkgs.python3}/bin/python3</string>
            <string>-m</string>
            <string>chroma</string>
            <string>run</string>
            <string>--host</string>
            <string>localhost</string>
            <string>--port</string>
            <string>8000</string>
            <string>--path</string>
            <string>${config.home.homeDirectory}/.local/share/chromadb</string>
        </array>
        <key>WorkingDirectory</key>
        <string>${config.home.homeDirectory}/.local/share/chromadb</string>
        <key>EnvironmentVariables</key>
        <dict>
            <key>CHROMA_DB_IMPL</key>
            <string>duckdb+parquet</string>
            <key>CHROMA_SERVER_HOST</key>
            <string>localhost</string>
            <key>CHROMA_SERVER_HTTP_PORT</key>
            <string>8000</string>
            <key>CHROMA_PERSIST_DIRECTORY</key>
            <string>${config.home.homeDirectory}/.local/share/chromadb</string>
        </dict>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>${config.home.homeDirectory}/.local/state/goose/logs/ai/chromadb.log</string>
        <key>StandardErrorPath</key>
        <string>${config.home.homeDirectory}/.local/state/goose/logs/ai/chromadb-error.log</string>
    </dict>
    </plist>
  '';
in
lib.mkIf claudeEnabled {
  home.packages = with pkgs; [
    chroma
    python3Packages.chromadb
    python3Packages.requests
  ];

  home.activation.claudeYarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "yarn" claudeYarnPackages
  );

  home.activation.claudeUvPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "uv" claudeUvPackages
  );

  # Create directories and configuration files
  home.activation.claudeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create necessary directories
    mkdir -p ${config.home.homeDirectory}/.claude
    mkdir -p ${config.home.homeDirectory}/.local/share/chromadb
    mkdir -p ${config.home.homeDirectory}/.local/share/goose/logs/ai
    mkdir -p ${config.home.homeDirectory}/.local/share/goose/file_changes
    mkdir -p ${config.home.homeDirectory}/Library/LaunchAgents

    # Install Claude settings with hooks
    cp ${claudeSettings} ${config.home.homeDirectory}/.claude/settings.json

    # Install ChromaDB launchd service
    cp ${chromadbPlist} ${config.home.homeDirectory}/Library/LaunchAgents/com.sysinit.chromadb.plist

    # Load the ChromaDB service
    launchctl unload ${config.home.homeDirectory}/Library/LaunchAgents/com.sysinit.chromadb.plist 2>/dev/null || true
    launchctl load ${config.home.homeDirectory}/Library/LaunchAgents/com.sysinit.chromadb.plist

    echo "Claude Code hooks and ChromaDB service configured"
  '';

  # Create Claude settings symlink for project-specific settings
  home.file.".claude/settings.local.json".source = claudeSettings;

}
