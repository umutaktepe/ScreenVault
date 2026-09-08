# ScreenVault — Agent Execution Rules

## Flutter & Dart Commands
- Whenever running `flutter` or `dart` commands via the `run_command` tool, ALWAYS specify `BypassSandbox: true`.
- **Reason:** The Flutter SDK is installed in the user's home directory (`/home/umutaktepe/flutter/bin`), which is outside the isolated container sandbox mount. Setting `BypassSandbox: true` executes the command directly on the host OS where Flutter and Dart are in the PATH.
- For static analysis and linting, prefer the `dart-mcp-server` (`analyze_files`) tool first before invoking terminal commands.
- For live physical testing: The user performs live device tests exclusively on their physical device. Do NOT invoke ADB run or hot reload/restart via MCP or terminal unless explicitly asked.
