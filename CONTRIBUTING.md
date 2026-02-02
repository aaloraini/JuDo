# Contributing to JuDo

Thank you for your interest in contributing to JuDo! This document provides guidelines and information for contributors.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read and follow these guidelines in all interactions.

## Getting Started

### Prerequisites

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 14.0 or later
- **Git**: For version control
- **Basic Swift/SwiftUI knowledge**: Understanding of iOS/macOS development

### Development Setup

1. **Fork the Repository**:
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/JuDo.git
   cd JuDo
   ```

2. **Add Upstream Remote**:
   ```bash
   git remote add upstream https://github.com/aaloraini/JuDo.git
   ```

3. **Create Development Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Open in Xcode**:
   ```bash
   open JuDo.xcodeproj
   ```

## Development Workflow

### Branch Strategy

- **main**: Stable release branch
- **develop**: Integration branch for new features
- **feature/***: Feature-specific branches
- **bugfix/***: Bug fix branches
- **hotfix/***: Critical fixes for release

### Making Changes

1. **Create Issue**: First, create an issue to discuss the change
2. **Create Branch**: Create a feature branch from `develop`
3. **Implement Changes**: Make your changes following coding standards
4. **Test Thoroughly**: Test your changes manually and with unit tests
5. **Update Documentation**: Update relevant documentation
6. **Submit Pull Request**: Create a PR to `develop` branch

### Code Standards

#### Swift Style Guide

Follow these Swift coding conventions:

```swift
// Use meaningful variable names
let taskManager = TaskManager()

// Use let over var when possible
let tasks = loadTasks()

// Use proper access control
class TaskManager: ObservableObject {
    private var tasksData: Data = Data()
    
    public func addTask(title: String) {
        // Implementation
    }
}

// Follow Swift naming conventions
struct Task: Codable, Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int
}
```

#### SwiftUI Guidelines

- Use SwiftUI best practices
- Prefer `@StateObject` over `@ObservedObject` for view-owned objects
- Use proper view composition
- Follow SwiftUI naming conventions

```swift
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
        // View implementation
    }
}
```

### Testing

#### Unit Tests

- Write unit tests for new functionality
- Test edge cases and error conditions
- Maintain test coverage above 80%

```swift
import XCTest
@testable import JuDo

class TaskManagerTests: XCTestCase {
    var taskManager: TaskManager!
    
    override func setUp() {
        super.setUp()
        taskManager = TaskManager()
    }
    
    func testAddTask() {
        taskManager.addTask(title: "Test Task")
        XCTAssertEqual(taskManager.tasks.count, 1)
        XCTAssertEqual(taskManager.tasks.first?.title, "Test Task")
    }
}
```

#### UI Tests

- Write UI tests for critical user flows
- Test widget functionality
- Ensure accessibility compliance

### Documentation

- Update relevant documentation for new features
- Add inline code comments for complex logic
- Update README.md if needed
- Update CHANGELOG.md for user-facing changes

## Types of Contributions

### Bug Fixes

1. **Report Bug**: Create an issue with detailed description
2. **Reproduce Bug**: Confirm you can reproduce the issue
3. **Write Test**: Add a test that fails before the fix
4. **Fix Bug**: Implement the fix
5. **Verify Fix**: Ensure test passes and bug is resolved

### New Features

1. **Proposal**: Create an issue to discuss the feature
2. **Design**: Consider the implementation and UI/UX impact
3. **Implementation**: Write the code following project standards
4. **Testing**: Add comprehensive tests
5. **Documentation**: Update relevant documentation

### Documentation

- Fix typos and grammatical errors
- Improve existing documentation
- Add new documentation for features
- Translate documentation (if applicable)

### Performance Improvements

- Profile the app to identify bottlenecks
- Optimize memory usage
- Improve widget performance
- Reduce app startup time

## Pull Request Process

### Before Submitting

1. **Test Changes**: Ensure all tests pass
2. **Code Review**: Self-review your changes
3. **Documentation**: Update relevant documentation
4. **Clean History**: Ensure commit history is clean

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Manual testing completed
- [ ] Widget functionality tested

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if user-facing change)
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs tests
2. **Code Review**: Maintainer reviews code changes
3. **Testing**: Reviewer tests changes if needed
4. **Approval**: PR approved and merged

## Project Structure

```
JuDo/
├── JuDo/                    # Main app source
│   ├── JuDoApp.swift       # App entry point
│   ├── ContentView.swift   # Main UI
│   ├── TaskManager.swift   # Data management
│   └── Task.swift          # Data model
├── JuDoWidget/             # Widget extension
│   ├── JuDoWidget.swift    # Widget implementation
│   └── Task.swift          # Shared model
├── JuDoTests/              # Unit tests
├── JuDoUITests/            # UI tests
├── docs/                   # Documentation
└── JuDo.xcodeproj/         # Xcode project
```

## Development Guidelines

### App Groups and Data Sharing

- Use the existing App Group: `group.com.aloraini.JuDo`
- Maintain data consistency between app and widget
- Test widget functionality thoroughly

### Widget Development

- Follow WidgetKit best practices
- Test timeline reload functionality
- Ensure proper data synchronization
- Test on different widget sizes

### Performance Considerations

- Optimize JSON encoding/decoding
- Minimize memory usage
- Test with large numbers of tasks
- Monitor widget performance

### Accessibility

- Ensure VoiceOver support
- Test keyboard navigation
- Use proper accessibility labels
- Follow macOS accessibility guidelines

## Release Process

### Version Management

- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version numbers in Xcode
- Update CHANGELOG.md with release notes

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated
- [ ] Release notes prepared

## Getting Help

### Resources

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit/)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

### Community

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For general questions and discussions
- **Code Reviews**: Participate in reviewing pull requests

## Recognition

Contributors will be recognized in:

- README.md contributors section
- Release notes for significant contributions
- Project documentation

## License

By contributing to JuDo, you agree that your contributions will be licensed under the same MIT license as the project.

## Questions?

If you have questions about contributing:

1. Check existing issues and discussions
2. Create a new issue with the "question" label
3. Review this documentation for guidance

Thank you for contributing to JuDo! Your contributions help make this project better for everyone.
