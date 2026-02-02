# App Store Submission Guide

This guide covers the process and requirements for submitting JuDo to the Mac App Store.

## Prerequisites

### Apple Developer Account

- **Active Membership**: Valid Apple Developer Program membership
- **Legal Entity**: Proper legal entity setup for app distribution
- **Tax Information**: Complete tax and banking information in App Store Connect

### Technical Requirements

- **Xcode**: 14.0 or later
- **macOS**: 13.0 (Ventura) or later for development
- **Code Signing**: Valid distribution certificates and provisioning profiles
- **App Store Connect**: Access to App Store Connect for app management

## App Store Configuration

### App Information

**Basic Details**:
- **App Name**: JuDo
- **Subtitle**: Simple Task Management
- **Category**: Productivity
- **Primary Category**: Productivity
- **Secondary Category**: (Optional) Utilities

**App Description**:
```
JuDo is a minimal and elegant task management app for macOS with WidgetKit integration. 

Features:
• Simple and intuitive task management
• Drag and drop task reordering
• Hide/show completed tasks
• WidgetKit integration for desktop widgets
• Keyboard shortcuts for quick task creation
• Native macOS design with SwiftUI
• Offline functionality with local data storage

Perfect for personal task management with a clean, distraction-free interface.
```

**Keywords**:
`task, todo, productivity, widget, reminder, organizer, checklist, macos`

**Support URL**: `https://github.com/aaloraini/JuDo/issues`
**Marketing URL**: `https://github.com/aaloraini/JuDo`
**Privacy Policy**: Not required (no data collection)

### App Privacy

**Data Collection**: None
**Data Types**: No data collected or shared
**Purpose**: Not applicable

## Technical Requirements

### Code Signing

**Distribution Certificate**:
1. Create a distribution certificate in Apple Developer portal
2. Download and install in Xcode
3. Configure in project settings

**Provisioning Profile**:
1. Create Mac App Store provisioning profile
2. Include App Groups capability
3. Associate with correct Bundle ID

### App Groups Configuration

**Required App Groups**:
- `group.com.aloraini.JuDo` (for data sharing between app and widget)

**Configuration Steps**:
1. Enable App Groups in Apple Developer portal
2. Add App Groups to both main app and widget extension
3. Update entitlements files accordingly

### Bundle Identifier

**Main App**: `com.aloraini.JuDo`
**Widget Extension**: `com.aloraini.JuDo.JuDoWidget`

**Requirements**:
- Unique reverse domain notation
- Consistent across development and distribution
- Matches App Store Connect configuration

## Build Configuration

### Release Build Settings

**Build Configuration**: Release
**Architecture**: Universal (Apple Silicon + Intel)
**Deployment Target**: macOS 13.0
**Swift Language Version**: Swift 5

### Archive Creation

```bash
# Create archive
xcodebuild archive \
    -project JuDo.xcodeproj \
    -scheme JuDo \
    -configuration Release \
    -archivePath ./build/JuDo.xcarchive \
    -destination generic/platform=macOS

# Validate archive
xcodebuild -exportArchive \
    -archivePath ./build/JuDo.xcarchive \
    -exportPath ./build \
    -exportOptionsPlist ExportOptions.plist
```

### Export Options

**ExportOptions.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

## App Store Connect Setup

### App Creation

1. **Sign in** to App Store Connect
2. **Go to** "My Apps"
3. **Click** "+" to create new app
4. **Fill in** app information:
   - Platform: macOS
   - Name: JuDo
   - Primary Language: English
   - Bundle ID: com.aloraini.JuDo
   - SKU: JUDO001

### App Metadata

**App Information**:
- **Status**: Prepare for Submission
- **Price**: Free (or chosen price tier)
- **Availability**: All countries

**App Store Information**:
- **Description**: Use provided description
- **Keywords**: Use provided keywords
- **Support URL**: GitHub issues page
- **Marketing URL**: GitHub repository
- **Privacy Policy**: Not required

### App Review Information

**Review Notes**:
```
JuDo is a simple task management app with WidgetKit integration. 

Key features to test:
1. Task creation, completion, and deletion
2. Drag and drop reordering
3. Hide/show completed tasks toggle
4. Widget functionality (add to desktop and test)
5. Keyboard shortcuts (Cmd+N for new task)
6. URL scheme handling (judo://add)

The app uses App Groups for data sharing between the main app and widget extension. All data is stored locally using UserDefaults with no network dependencies.

Test on both Apple Silicon and Intel Macs if possible.
```

**Contact Information**:
- **Review Contact**: Developer contact information
- **Demo Account**: Not required (no login)

## App Store Review Guidelines

### Compliance Checklist

**Functionality**:
- ✅ App functions as described
- ✅ No crashes or major bugs
- ✅ Follows macOS Human Interface Guidelines
- ✅ Proper widget implementation

**Content**:
- ✅ No inappropriate content
- ✅ Accurate metadata and descriptions
- ✅ Proper use of Apple trademarks

**Technical**:
- ✅ Proper code signing
- ✅ No private APIs
- ✅ Proper use of App Groups
- ✅ WidgetKit compliance

**Business**:
- ✅ Clear pricing information
- ✅ Proper app categorization
- ✅ Accurate screenshots

### Common Rejection Reasons

**Widget Issues**:
- Widget not appearing or functioning
- Improper App Groups configuration
- Timeline reload problems

**Data Storage**:
- Improper use of UserDefaults
- Data persistence issues
- App Groups sharing problems

**UI/UX**:
- Non-standard macOS interface
- Poor user experience
- Accessibility issues

## Screenshots and Media

### Required Screenshots

**Mac App Store**:
- **1280x800**: Minimum 3 screenshots
- **1440x900**: Recommended for better quality

**Screenshot Content**:
1. **Main Interface**: Task list with sample tasks
2. **Add Task**: Sheet interface for adding new tasks
3. **Widget**: Widget on desktop with tasks
4. **Settings**: Hide completed tasks toggle
5. **Keyboard Shortcuts**: Cmd+N in action

### App Preview (Optional)

- **Format**: MP4 video
- **Duration**: 15-30 seconds
- **Resolution**: 1920x1080 or higher
- **Content**: Demonstrate key features

## Testing Before Submission

### Internal Testing

1. **Functionality Test**: All features working correctly
2. **Widget Test**: Add, use, and remove widgets
3. **Data Sync Test**: Verify app-widget data sharing
4. **Performance Test**: Check memory and CPU usage
5. **Compatibility Test**: Test on different macOS versions

### TestFlight Testing

1. **Internal Test**: Upload to TestFlight for internal testing
2. **Beta Testing**: Invite external testers for feedback
3. **Bug Fixes**: Address issues found during testing

## Submission Process

### Upload to App Store Connect

```bash
# Using Xcode Organizer
1. Product → Archive
2. Distribute App → App Store Connect
3. Choose correct team and app
4. Upload build

# Using command line
xcodebuild -exportArchive \
    -archivePath ./build/JuDo.xcarchive \
    -exportPath ./build \
    -exportOptionsPlist ExportOptions.plist \
    -uploadToAppStore
```

### Submit for Review

1. **Complete Metadata**: Fill in all required information
2. **Upload Screenshots**: Add required screenshots
3. **Set Price**: Choose appropriate price tier
4. **Submit**: Click "Submit for Review"

### Review Timeline

- **Standard Review**: 1-7 business days
- **Expedited Review**: Available for critical bug fixes
- **Rejection**: Address feedback and resubmit

## Post-Submission

### Release Management

**Release Types**:
- **Automatic Release**: Approved immediately after review
- **Manual Release**: Hold for specific release date
- **Phased Release**: Gradual rollout to users

### Version Updates

**Update Process**:
1. Increment version number
2. Test thoroughly
3. Update release notes
4. Submit for review

### Analytics and Monitoring

**App Store Connect Analytics**:
- Downloads and installs
- Crash reports
- Performance metrics
- User engagement

## Troubleshooting

### Common Upload Issues

**Invalid Binary**:
- Check code signing certificates
- Verify provisioning profiles
- Ensure correct Bundle ID

**Metadata Rejection**:
- Review app description
- Check keyword usage
- Verify screenshot compliance

### Review Rejection

**Common Reasons**:
- Widget functionality issues
- App Groups configuration problems
- UI/UX guideline violations
- Missing features or functionality

**Resolution**:
1. Read review feedback carefully
2. Fix identified issues
3. Test thoroughly
4. Resubmit with explanation

## Best Practices

### Before Submission

1. **Test Thoroughly**: Ensure all features work correctly
2. **Follow Guidelines**: Adhere to Apple's review guidelines
3. **Prepare Assets**: Have all screenshots and media ready
4. **Review Metadata**: Double-check all app information

### During Review

1. **Monitor Status**: Check App Store Connect regularly
2. **Be Responsive**: Respond quickly to review requests
3. **Prepare for Rejection**: Have fixes ready for common issues

### After Approval

1. **Monitor Performance**: Track downloads and crashes
2. **User Feedback**: Respond to reviews and support requests
3. **Regular Updates**: Maintain app with bug fixes and improvements

This guide should help ensure a smooth App Store submission process for JuDo.
