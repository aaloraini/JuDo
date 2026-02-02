# Building from Source

This guide covers how to build JuDo from source code for development and testing purposes.

## Development Environment

### Required Tools

- **Xcode**: 14.0 or later
- **macOS**: 13.0 (Ventura) or later
- **Swift**: 5.0+ (included with Xcode)
- **Git**: For cloning the repository

### Optional Tools

- **SwiftLint**: For code style consistency
- **SwiftFormat**: For code formatting
- **XcodeGen**: For project generation (if modifying project structure)

## Getting the Source Code

```bash
# Clone the repository
git clone https://github.com/aaloraini/JuDo.git
cd JuDo

# Checkout the main branch
git checkout main
```

## Project Structure

```
JuDo/
├── JuDo/                    # Main app source code
│   ├── JuDoApp.swift       # App entry point
│   ├── ContentView.swift   # Main UI view
│   ├── Task.swift          # Task data model
│   ├── TaskManager.swift   # Data management
│   └── Assets.xcassets/    # App assets
├── JuDoWidget/             # Widget extension
│   ├── JuDoWidget.swift    # Widget implementation
│   ├── JuDoWidgetControl.swift # Control Center widget
│   ├── JuDoWidgetBundle.swift # Widget bundle
│   └── Task.swift          # Shared Task model
├── JuDoTests/              # Unit tests
├── JuDoUITests/            # UI tests
└── JuDo.xcodeproj/         # Xcode project file
```

## Building the Project

### Using Xcode

1. **Open the Project**:
   ```bash
   open JuDo.xcodeproj
   ```

2. **Select Target**:
   - Choose "JuDo" for the main app
   - Choose "JuDoWidget" for the widget extension

3. **Build Configuration**:
   - **Debug**: For development and testing
   - **Release**: For production builds

4. **Build**:
   - Press `Cmd+B` to build
   - Press `Cmd+R` to run the app

### Using Command Line

```bash
# Build the main app
xcodebuild -project JuDo.xcodeproj -scheme JuDo -configuration Debug build

# Build the widget extension
xcodebuild -project JuDo.xcodeproj -scheme JuDoWidget -configuration Debug build

# Build for release
xcodebuild -project JuDo.xcodeproj -scheme JuDo -configuration Release build
```

## Development Setup

### 1. Configure Signing

1. Open **JuDo.xcodeproj** in Xcode
2. Select the **JuDo** project in the navigator
3. Go to **Signing & Capabilities** tab
4. Configure:
   - **Team**: Your Apple Developer account
   - **Bundle Identifier**: Unique identifier for your build
   - **Provisioning Profile**: Automatic or manual

### 2. App Group Configuration

Both the main app and widget extension use App Groups for data sharing:

1. **Main App (JuDo)**:
   - Go to **Signing & Capabilities**
   - Add **App Groups** capability
   - Add: `group.com.aloraini.JuDo`

2. **Widget Extension (JuDoWidget)**:
   - Go to **Signing & Capabilities**
   - Add **App Groups** capability
   - Add: `group.com.aloraini.JuDo`

### 3. URL Scheme Configuration

The app registers the `judo://` URL scheme for widget communication:

1. Open **Info.plist** in the JuDo target
2. Verify URL Types configuration:
   - **URL Schemes**: `judo`
   - **URL Identifier**: `com.aloraini.judo`

## Testing

### Running Tests

```bash
# Run unit tests
xcodebuild test -project JuDo.xcodeproj -scheme JuDo -destination 'platform=macOS'

# Run UI tests
xcodebuild test -project JuDo.xcodeproj -scheme JuDo -destination 'platform=macOS' -only-testing:JuDoUITests
```

### Widget Testing

1. **Build and Run** the main app
2. **Add Widget** to your desktop:
   - Right-click desktop → Edit Widgets
   - Find "JuDo Tasks"
   - Add to desktop
3. **Test Functionality**:
   - Add tasks from main app
   - Toggle completion from widget
   - Verify data sync

## Debugging

### Main App Debugging

1. Set breakpoints in Xcode
2. Use Console.app for system logs
3. Check App Group data:
   ```bash
   defaults read group.com.aloraini.JuDo
   ```

### Widget Debugging

1. **Widget Debug Console**:
   - Open Console.app
   - Filter by "JuDoWidget"
   - Look for widget timeline events

2. **Widget Timeline Issues**:
   - Check `WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")` calls
   - Verify App Group data sharing

## Code Style

### Swift Style Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 4 spaces for indentation
- Prefer `let` over `var` when possible
- Use meaningful variable and function names

### Linting (Optional)

```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint

# Auto-fix issues
swiftlint --fix
```

## Common Build Issues

### "App Group not found"

1. Verify App Groups are enabled in both targets
2. Check Bundle Identifier matches entitlements
3. Clean and rebuild the project

### "Widget not appearing"

1. Ensure widget extension is built successfully
2. Verify App Groups are correctly configured
3. Restart the widget system (restart Mac)

### "Code signing errors"

1. Check your Apple Developer account status
2. Verify provisioning profiles are valid
3. Update Bundle Identifier if needed

## Release Build

### Creating Archive

```bash
# Archive for distribution
xcodebuild archive -project JuDo.xcodeproj -scheme JuDo -archivePath ./build/JuDo.xcarchive

# Export archive
xcodebuild -exportArchive -archivePath ./build/JuDo.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
```

### App Store Distribution

1. **Archive** the app in Xcode
2. **Validate** the archive
3. **Distribute** to App Store Connect
4. Follow App Store submission guidelines in [APP_STORE_NOTES.md](APP_STORE_NOTES.md)

## Contributing

Before submitting changes:

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** your changes thoroughly
4. **Update** documentation if needed
5. **Submit** a pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed contribution guidelines.
