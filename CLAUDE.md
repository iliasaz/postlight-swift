# CLAUDE.md - AI Assistant Guide for postlight-swift

This document provides guidance for AI assistants working with this Swift library project using Swift 6 concurrency.

## Project Overview

This is a Swift library with:
- **Swift 6.x** - With modern structured concurrency
- **Swift Package Manager** - For dependency management
- **CLI utility** - For testing and demonstration

## Project Structure

```
postlight-swift/
├── Package.swift              # Swift package manifest
├── Sources/
│   ├── PostlightSwift/        # Main library
│   │   ├── Models/            # Data models
│   │   ├── Services/          # Core functionality
│   │   └── Extensions/        # Swift extensions
│   └── postlight-cli/         # CLI utility for testing
│       └── main.swift
├── Tests/
│   └── PostlightSwiftTests/   # Unit tests
└── CLAUDE.md
```

## Build and Run Commands

```bash
# Build the project
swift build

# Run the CLI utility
swift run postlight-cli

# Build for release
swift build -c release

# Run tests
swift test

# Clean build artifacts
swift package clean

# Update dependencies
swift package update
```

## Package.swift Conventions

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PostlightSwift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PostlightSwift",
            targets: ["PostlightSwift"]
        ),
        .executable(
            name: "postlight-cli",
            targets: ["postlight-cli"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "PostlightSwift",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "postlight-cli",
            dependencies: [
                "PostlightSwift",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "PostlightSwiftTests",
            dependencies: ["PostlightSwift"]
        ),
    ]
)
```

## Swift 6 Concurrency Best Practices

### Core Principles

1. **Start simple**: Use `async/await` for asynchronous operations
2. **Use `actor`** for shared mutable state
3. **Prefer structured concurrency** with task groups
4. **Mark types as `Sendable`** when they cross concurrency boundaries

### Sendable Conformance

All types shared across concurrency boundaries must conform to `Sendable`:

```swift
// Immutable struct is implicitly Sendable
struct Result: Sendable {
    let id: UUID
    let value: String
}

// Actor for mutable shared state
actor Cache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    func get(_ key: Key) -> Value? {
        storage[key]
    }

    func set(_ key: Key, value: Value) {
        storage[key] = value
    }
}
```

### Task Management

```swift
// Prefer TaskGroup for concurrent operations
func processAll(items: [Item]) async throws -> [Result] {
    try await withThrowingTaskGroup(of: Result.self) { group in
        for item in items {
            group.addTask {
                try await self.process(item)
            }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

### Actor Best Practices

```swift
actor StateManager {
    private var state: State = .initial

    func update(_ newState: State) {
        state = newState
    }

    // Use nonisolated for operations that don't need actor isolation
    nonisolated var description: String {
        "StateManager"
    }
}
```

## Code Style Guidelines

### Naming Conventions

- **Types**: `PascalCase` (e.g., `DataProcessor`, `ResultCache`)
- **Functions/Methods**: `camelCase` (e.g., `fetchData`, `processItem`)
- **Variables**: `camelCase` (e.g., `itemCount`, `currentState`)
- **Constants**: `camelCase` (e.g., `defaultTimeout`, `maxRetries`)
- **File names**: Match primary type (e.g., `DataProcessor.swift`)
- **Extensions**: `Type+Feature.swift` (e.g., `String+Validation.swift`)

### Documentation

Write documentation comments for public APIs:

```swift
/// Processes the given input and returns a result.
/// - Parameter input: The data to process.
/// - Returns: The processed result.
/// - Throws: `ProcessingError` if processing fails.
public func process(_ input: Input) async throws -> Result
```

### Error Handling

```swift
// Define domain-specific errors
public enum PostlightError: Error, LocalizedError {
    case invalidInput(String)
    case processingFailed(underlying: Error)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .processingFailed(let error):
            return "Processing failed: \(error.localizedDescription)"
        case .timeout:
            return "Operation timed out"
        }
    }
}
```

## Testing Patterns

### Unit Tests

```swift
import XCTest
@testable import PostlightSwift

final class ProcessorTests: XCTestCase {
    var sut: Processor!

    override func setUp() async throws {
        sut = Processor()
    }

    func testProcessReturnsExpectedResult() async throws {
        // Given
        let input = Input(value: "test")

        // When
        let result = try await sut.process(input)

        // Then
        XCTAssertEqual(result.value, "expected")
    }
}
```

### Testing Async Code

```swift
func testConcurrentOperations() async throws {
    let results = try await withThrowingTaskGroup(of: Result.self) { group in
        for i in 0..<10 {
            group.addTask {
                try await self.sut.process(Input(value: "\(i)"))
            }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }

    XCTAssertEqual(results.count, 10)
}
```

## CLI Utility

```swift
// Sources/postlight-cli/main.swift
import ArgumentParser
import PostlightSwift

@main
struct PostlightCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "postlight-cli",
        abstract: "CLI utility for testing PostlightSwift"
    )

    @Argument(help: "Input to process")
    var input: String

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false

    func run() async throws {
        let processor = Processor()
        let result = try await processor.process(input)
        print(result)
    }
}
```

## Git Workflow

- Main branch: `main`
- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Commit messages: Use conventional commits (e.g., `feat:`, `fix:`, `docs:`)

## Useful Resources

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Package Manager](https://www.swift.org/documentation/package-manager/)
