# VS Code Shell Integration Setup for TELOS

## Overview
VS Code shell integration has been configured to provide enhanced terminal functionality for TELOS development, including command decorations, sticky scroll, IntelliSense, and improved navigation.

## Configuration Applied

### Global VS Code Settings (`%APPDATA%\Code\User\settings.json`)
- **Default Terminal**: WSL (Ubuntu)
- **Shell Integration**: Enabled with full decorations
- **Command Guide**: Enabled for visual command boundaries
- **Sticky Scroll**: Enabled for command visibility
- **IntelliSense**: Enabled for terminal suggestions
- **Persistent Sessions**: Enabled for session continuity

### Workspace Settings (`.vscode/settings.json`)
- **Terminal CWD**: Set to workspace root
- **File Associations**: `*.io` files associated with Io language
- **Search Exclusions**: Build artifacts and dependencies excluded
- **Language-Specific Settings**: Formatting and editor configurations

### Shell Configuration (`.bashrc`)
- **TELOS Environment**: Automatic setup on shell launch
- **Shell Integration**: VS Code integration script loaded
- **Custom Functions**: `telos_env_check()`, `telos_rebuild()`, `telos_health()`
- **TELOS Prompt**: Custom prompt indicator `[TELOS]`

## Features Enabled

### Command Decorations
- Blue circles for successful commands
- Red circles with crosses for failed commands
- Clickable decorations for command actions (rerun, copy output)

### Sticky Scroll
- Commands remain visible at top of terminal when scrolling
- Easy identification of command output boundaries

### Command Navigation
- `Ctrl+Up/Ctrl+Down` to navigate between commands
- `Shift+Ctrl+Up/Ctrl+Down` to select command output

### IntelliSense in Terminal
- File/folder/command completion
- Trigger with `Ctrl+Space`
- Inline suggestions and status bar

### Enhanced Accessibility
- Audio cues for command failures
- Improved screen reader support
- Keyboard shortcuts for navigation

## Verification

To verify shell integration is working:

1. **Open VS Code Terminal** (`Ctrl+``)
2. **Check Terminal Tab**: Hover to see shell integration quality ("Rich", "Basic", or "None")
3. **Run Commands**: Observe blue/red decorations appear beside commands
4. **Scroll Terminal**: Commands should "stick" to top when partially visible
5. **Use Navigation**: `Ctrl+Up/Down` should jump between commands
6. **Try IntelliSense**: Type partial commands and press `Ctrl+Space`

## TELOS-Specific Features

### Environment Functions
```bash
telos_env_check    # Verify all TELOS environment variables
telos_rebuild      # Clean rebuild TELOS system
telos_health       # Run health check suite
```

### Automatic Setup
- Environment variables set automatically on shell launch
- Working directory set to TELOS root
- Library paths configured for Io addons
- Python paths configured for modules

## Troubleshooting

### Shell Integration Not Working
1. Check VS Code version (1.74+ required for full features)
2. Verify WSL terminal is default profile
3. Ensure `.bashrc` contains the integration line
4. Restart VS Code and terminal

### Decorations Not Showing
1. Check `terminal.integrated.shellIntegration.decorationsEnabled` setting
2. Verify shell integration quality is "Rich" or "Basic"
3. Try running commands that produce output

### IntelliSense Not Working
1. Check `terminal.integrated.suggest.enabled` is true
2. Verify shell integration is active
3. Try manual trigger with `Ctrl+Space`

## Advanced Configuration

### Custom Keyboard Shortcuts
Add to `keybindings.json` for enhanced terminal workflow:
```json
{
    "key": "ctrl+alt+r",
    "command": "workbench.action.terminal.runRecentCommand",
    "when": "terminalFocus"
}
```

### Performance Tuning
- Adjust `terminal.integrated.shellIntegration.history` for command history depth
- Configure `terminal.integrated.suggest.*` settings for suggestion behavior
- Use `terminal.integrated.persistentSessionReviveProcess` for session handling