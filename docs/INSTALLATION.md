# Installation Guide

This guide covers how to install and set up JuDo on your Mac.

## System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Architecture**: Apple Silicon or Intel Mac
- **Storage**: ~10 MB of available disk space

## Installation Methods

### Method 1: App Store (Recommended)

1. Open the App Store on your Mac
2. Search for "JuDo"
3. Click "Get" to download and install
4. Launch JuDo from your Applications folder or Launchpad

### Method 2: Direct Download

1. Visit the [JuDo Releases](https://github.com/aaloraini/JuDo/releases) page
2. Download the latest `.dmg` file
3. Double-click the downloaded file to mount it
4. Drag JuDo to your Applications folder
5. Eject the disk image and launch the app

### Method 3: Homebrew Cask

```bash
brew install --cask judo
```

## First-Time Setup

1. **Launch JuDo** from your Applications folder
2. **Grant Permissions**: The app may request permissions for:
   - Notifications (for task reminders - optional)
   - Accessibility (for keyboard shortcuts - optional)
3. **Add Widgets** (optional):
   - Right-click your desktop
   - Select "Edit Widgets"
   - Find "JuDo Tasks" in the widget list
   - Drag to your preferred location

## Widget Setup

### Adding JuDo Widgets

1. Open **Notification Center** or enter **Edit Widget Mode**
2. Click the **"+"** button to add widgets
3. Search for "JuDo Tasks"
4. Choose between:
   - **Medium Widget**: Shows up to 5 tasks
   - **Large Widget**: Shows up to 8 tasks

### Widget Permissions

JuDo widgets require:
- **App Group Access**: Automatically configured during installation
- **Network Access**: Not required (works offline)

## Troubleshooting Installation

### "App can't be opened because Apple cannot check it for malicious software"

This is a common security feature on macOS. To resolve:

1. **Right-click** the JuDo app and select "Open"
2. Click "Open" in the confirmation dialog
3. Or, go to **System Settings > Privacy & Security** and click "Open Anyway"

### Widget Not Appearing

If JuDo widgets don't show up in the widget gallery:

1. **Restart your Mac** to refresh the widget system
2. **Verify Installation**: Ensure JuDo is in your Applications folder
3. **Check Permissions**: Make sure the app has necessary permissions

### Data Not Syncing Between App and Widget

1. **Restart JuDo** to refresh App Group data
2. **Wait for Widget Refresh**: WidgetKit controls widget update timing
3. **Add a New Task**: This triggers an immediate widget timeline reload

## Uninstallation

### Removing JuDo

1. Drag JuDo from Applications folder to Trash
2. Empty Trash to complete removal

### Removing Widget Data

JuDo stores data in App Group UserDefaults. To completely remove:

```bash
# Remove App Group data (advanced users only)
defaults delete group.com.aloraini.JuDo
```

## Migration from Previous Versions

If upgrading from a pre-2.0.0 version:

1. **Backup Current Data**: Export important tasks if needed
2. **Install New Version**: Follow standard installation
3. **Data Migration**: Tasks should automatically migrate to the new format
4. **Verify Migration**: Check that all tasks appear correctly

## Getting Help

- **Documentation**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- **GitHub Issues**: Report bugs at [https://github.com/aaloraini/JuDo/issues](https://github.com/aaloraini/JuDo/issues)
- **Support**: Contact support for installation assistance
