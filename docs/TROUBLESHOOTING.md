# Troubleshooting Guide

This guide addresses common issues and solutions for JuDo and its widget integration.

## General Issues

### App Won't Launch

**Symptoms**: App crashes immediately or doesn't open

**Solutions**:
1. **Check macOS Version**: Ensure you're running macOS 13.0 (Ventura) or later
2. **Verify Installation**: Reinstall from App Store or official download
3. **Check Permissions**: Ensure app has necessary permissions in System Settings
4. **Reset App**: Delete and reinstall the app

```bash
# Remove app data (last resort)
defaults delete group.com.aloraini.JuDo
```

### App Freezes or Becomes Unresponsive

**Symptoms**: UI stops responding to user input

**Solutions**:
1. **Force Quit**: Press `Cmd+Option+Esc` and force quit JuDo
2. **Restart App**: Relaunch after force quit
3. **Check Memory**: Monitor Activity Monitor for memory usage
4. **Reduce Task Count**: If you have 1000+ tasks, consider archiving old ones

## Data Issues

### Tasks Not Saving

**Symptoms**: Added tasks disappear when app is restarted

**Solutions**:
1. **Check App Groups**: Verify App Group entitlements are properly configured
2. **Disk Space**: Ensure sufficient disk space is available
3. **Permissions**: Check app has write permissions
4. **Reset Data**: Clear corrupted data and start fresh

```bash
# Check App Group data
defaults read group.com.aloraini.JuDo

# Reset corrupted data
defaults delete group.com.aloraini.JuDo
```

### Tasks Not Syncing Between App and Widget

**Symptoms**: Changes in app don't appear in widget or vice versa

**Solutions**:
1. **Restart Both**: Restart both the app and add widget again
2. **Wait for Refresh**: WidgetKit controls update timing; wait up to 15 minutes
3. **Force Reload**: Add a new task to trigger immediate widget reload
4. **Check App Groups**: Ensure both targets use the same App Group ID

### Data Corruption

**Symptoms**: App crashes when loading tasks or displays incorrect data

**Solutions**:
1. **Export Tasks**: Manually copy important tasks before resetting
2. **Reset Data**: Clear corrupted App Group data
3. **Rebuild Tasks**: Recreate task list from scratch

```bash
# Backup before reset (advanced)
defaults export group.com.aloraini.JuDo - > judo-backup.plist

# Reset corrupted data
defaults delete group.com.aloraini.JuDo

# Restore from backup (if needed)
defaults import group.com.aloraini.JuDo judo-backup.plist
```

## Widget Issues

### Widget Not Appearing in Widget Gallery

**Symptoms**: JuDo widget doesn't show up when adding widgets

**Solutions**:
1. **Restart Mac**: Restart your Mac to refresh widget system
2. **Check Installation**: Ensure JuDo is properly installed in Applications
3. **Verify Widget Extension**: Check that JuDoWidget extension is enabled
4. **Update macOS**: Ensure you're running the latest macOS version

### Widget Shows "No Tasks" When Tasks Exist

**Symptoms**: Widget displays empty state despite having tasks in app

**Solutions**:
1. **Add New Task**: Create a new task to trigger widget reload
2. **Wait for Refresh**: WidgetKit may delay updates
3. **Restart Widget**: Remove and re-add the widget
4. **Check App Groups**: Verify App Group sharing is working

### Widget Not Updating

**Symptoms**: Widget shows outdated task information

**Solutions**:
1. **Make Changes**: Add, complete, or delete a task to trigger reload
2. **Wait Longer**: WidgetKit controls update timing
3. **Restart Widget**: Remove and re-add the widget
4. **Check Console**: Look for widget errors in Console.app

```bash
# Monitor widget logs
log stream --predicate 'process == "JuDoWidget"'
```

### Widget Crashes

**Symptoms**: Widget disappears or shows error state

**Solutions**:
1. **Remove Widget**: Delete the widget from desktop
2. **Restart App**: Restart the main JuDo app
3. **Re-add Widget**: Add the widget back to desktop
4. **Check Console**: Review crash logs in Console.app

## Installation Issues

### "App Can't Be Opened" Security Error

**Symptoms**: macOS blocks app from opening with security warning

**Solutions**:
1. **Right-Click Open**: Right-click app and select "Open"
2. **System Settings**: Go to System Settings > Privacy & Security > "Open Anyway"
3. **Gatekeeper**: Temporarily disable Gatekeeper (not recommended)

```bash
# Remove quarantine attribute (advanced)
sudo xattr -rd com.apple.quarantine /Applications/JuDo.app
```

### Code Signing Issues

**Symptoms**: App fails to install or run with signing errors

**Solutions**:
1. **Official Download**: Download from App Store or official GitHub releases
2. **Verify Integrity**: Check file checksum if available
3. **Reinstall**: Delete and reinstall the app

## Performance Issues

### Slow App Performance

**Symptoms**: App is sluggish or unresponsive with many tasks

**Solutions**:
1. **Reduce Task Count**: Archive or delete completed tasks
2. **Restart App**: Quit and relaunch the app
3. **Check Resources**: Monitor CPU and memory usage in Activity Monitor
4. **Update macOS**: Ensure you're running the latest macOS version

### High Memory Usage

**Symptoms**: App uses excessive memory

**Solutions**:
1. **Restart App**: Quit and relaunch to clear memory
2. **Check Task Count**: Large numbers of tasks may increase memory usage
3. **Monitor Activity**: Use Activity Monitor to track memory usage

## Development Issues

### Build Failures

**Symptoms**: Xcode build fails with errors

**Solutions**:
1. **Clean Build**: Product → Clean Build Folder in Xcode
2. **Update Xcode**: Ensure you're using Xcode 14.0 or later
3. **Check Dependencies**: Verify all required frameworks are available
4. **Reset Simulators**: Reset iOS/macOS simulators if applicable

### Widget Extension Not Building

**Symptoms**: Widget extension fails to build or run

**Solutions**:
1. **Check Entitlements**: Verify App Groups entitlements in both targets
2. **Bundle IDs**: Ensure bundle identifiers are unique and correct
3. **Code Signing**: Configure proper code signing for widget extension
4. **Clean Build**: Clean and rebuild the entire project

## Debugging Tools

### Console.app

Monitor system and app logs:

1. Open Console.app
2. Filter by "JuDo" for main app logs
3. Filter by "JuDoWidget" for widget logs
4. Look for error messages or crash reports

### Activity Monitor

Monitor resource usage:

1. Open Activity Monitor
2. Find "JuDo" in process list
3. Monitor CPU, memory, and disk usage
4. Check for unusual resource consumption

### UserDefaults Inspection

Check App Group data:

```bash
# Read all App Group data
defaults read group.com.aloraini.JuDo

# Read specific key
defaults read group.com.aloraini.JuDo tasks

# Check data format
defaults export group.com.aloraini.JuDo - | plutil -
```

## Getting Help

### Report Issues

When reporting issues, include:

1. **macOS Version**: System Settings → General → About
2. **JuDo Version**: Help menu → About JuDo
3. **Steps to Reproduce**: Detailed description of the issue
4. **Expected Behavior**: What you expected to happen
5. **Actual Behavior**: What actually happened
6. **Console Logs**: Relevant error messages from Console.app

### Contact Support

- **GitHub Issues**: [https://github.com/aaloraini/JuDo/issues](https://github.com/aaloraini/JuDo/issues)
- **Documentation**: See other docs in the `/docs` folder
- **Community**: Check for discussions or community support

## Preventive Measures

### Regular Maintenance

1. **Update Regularly**: Keep JuDo and macOS updated
2. **Monitor Performance**: Watch for unusual behavior
3. **Backup Data**: Periodically export important tasks
4. **Clean Up**: Archive or delete old completed tasks

### Best Practices

1. **Reasonable Task Count**: Keep task list manageable
2. **Regular Restarts**: Restart app periodically
3. **Monitor Storage**: Ensure sufficient disk space
4. **Report Issues**: Report problems promptly for faster resolution

This troubleshooting guide should help resolve most common issues with JuDo. For persistent problems, please report them through the official channels.
