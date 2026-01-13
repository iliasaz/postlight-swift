# CLAUDE.md - AI Assistant Guide for postlight-swift

This document provides guidance for AI assistants working with this server-side Swift project using Swift 6 concurrency.

## Project Overview

This is a server-side Swift project built with:
- **Swift 6.x** - With modern structured concurrency
- **Swift Package Manager** - For dependency management

## Project Structure

```
postlight-swift/
├── Package.swift              # Swift package manifest
├── Sources/
│   └── App/
│       ├── App.swift          # Entry point with @main
│       ├── Models/            # Data models and DTOs
│       ├── Services/          # Business logic layer
│       └── Extensions/        # Swift extensions
├── Tests/
│   └── AppTests/              # Unit and integration tests
├── Resources/                 # Static files, resources
└── CLAUDE.md
```

## Build and Run Commands

```bash
# Build the project
swift build

# Run the application
swift run App

# Build for release
swift build -c release

# Run tests
swift test

# Clean build artifacts
swift package clean

# Update dependencies
swift package update

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## Package.swift Conventions

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"]
        ),
    ]
)
```

## Swift 6 Concurrency Best Practices

### Core Principles

1. **Start simple**: Use `async/await` for asynchronous operations
2. **Use `@MainActor`** for UI-related code (if applicable)
3. **Use `actor`** for shared mutable state
4. **Prefer structured concurrency** with task groups

### Sendable Conformance

All types shared across concurrency boundaries must conform to `Sendable`:

```swift
// Good - immutable struct is implicitly Sendable
struct UserDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let email: String
}

// Good - actor for mutable shared state
actor UserCache {
    private var cache: [UUID: User] = [:]

    func get(_ id: UUID) -> User? {
        cache[id]
    }

    func set(_ user: User) {
        cache[user.id] = user
    }
}
```

### Task Management

```swift
// Prefer TaskGroup for concurrent operations
func fetchAllUsers(ids: [UUID]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await self.fetchUser(id: id)
            }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}

// Use Task for fire-and-forget operations
Task {
    await analytics.track(event: .userLoggedIn)
}
```

### Actor Best Practices

```swift
// Use actors for thread-safe state management
actor DatabasePool {
    private var connections: [Connection] = []

    func acquire() async -> Connection {
        // Thread-safe connection management
    }

    // Use nonisolated for operations that don't need actor isolation
    nonisolated func connectionCount() -> Int {
        // This can be called without awaiting
    }
}
```

### Async Sequences

```swift
// Use AsyncSequence for streaming data
func processItems() async throws {
    for await item in itemStream {
        try await process(item)
    }
}

// Create custom async sequences with AsyncStream
func makeStream() -> AsyncStream<Event> {
    AsyncStream { continuation in
        // Yield values asynchronously
        continuation.yield(.started)
        continuation.finish()
    }
}
```

## Application Entry Point

```swift
// Sources/App/App.swift
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var verbose: Bool = false

    func run() async throws {
        // Application logic here
    }
}
```

## Code Style Guidelines

### Naming Conventions

- **Types**: `PascalCase` (e.g., `UserService`, `DatabasePool`)
- **Functions/Methods**: `camelCase` (e.g., `fetchUser`, `validateToken`)
- **Variables**: `camelCase` (e.g., `userId`, `currentState`)
- **Constants**: `camelCase` (e.g., `defaultTimeout`, `maxRetries`)
- **File names**: Match primary type (e.g., `UserService.swift`)
- **Extensions**: `Type+Protocol.swift` (e.g., `User+Codable.swift`)

### Documentation

Write documentation comments for public APIs:

```swift
/// Fetches a user by their unique identifier.
/// - Parameter id: The UUID of the user to fetch.
/// - Returns: The user if found, nil otherwise.
/// - Throws: `DatabaseError` if the query fails.
func fetchUser(id: UUID) async throws -> User?
```

### Error Handling

```swift
// Define domain-specific errors
enum AppError: Error, LocalizedError {
    case userNotFound(UUID)
    case invalidInput(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .userNotFound(let id):
            return "User not found: \(id)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

## Testing Patterns

### Unit Tests

```swift
import XCTest
@testable import App

final class UserServiceTests: XCTestCase {
    var sut: UserService!
    var mockDatabase: MockDatabase!

    override func setUp() async throws {
        mockDatabase = MockDatabase()
        sut = UserService(database: mockDatabase)
    }

    func testFetchUserReturnsUser() async throws {
        // Given
        let expectedUser = User(id: UUID(), name: "Test")
        mockDatabase.users = [expectedUser]

        // When
        let result = try await sut.fetchUser(id: expectedUser.id)

        // Then
        XCTAssertEqual(result, expectedUser)
    }
}
```

### Testing Async Code

```swift
func testAsyncOperation() async throws {
    // Use async/await directly in tests
    let result = try await service.performOperation()
    XCTAssertNotNil(result)
}

func testWithTimeout() async throws {
    // Use Task with timeout for long-running operations
    let result = try await withThrowingTaskGroup(of: Result.self) { group in
        group.addTask {
            try await self.service.longOperation()
        }
        group.addTask {
            try await Task.sleep(for: .seconds(5))
            throw TimeoutError()
        }
        return try await group.next()!
    }
}
```

## Common Dependencies

```swift
// Typical server-side Swift dependencies
.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
.package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
.package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
.package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.20.0"),
```

## Environment Configuration

```swift
// Use environment variables for configuration
struct Config {
    let apiKey: String
    let debugMode: Bool
    let port: Int

    init() throws {
        guard let key = ProcessInfo.processInfo.environment["API_KEY"] else {
            throw ConfigError.missingEnvironmentVariable("API_KEY")
        }
        self.apiKey = key
        self.debugMode = ProcessInfo.processInfo.environment["DEBUG"] == "true"
        self.port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080
    }
}
```

## Docker Support

```dockerfile
# Dockerfile
FROM swift:6.0-jammy as builder
WORKDIR /app
COPY . .
RUN swift build -c release

FROM swift:6.0-jammy-slim
WORKDIR /app
COPY --from=builder /app/.build/release/App .
CMD ["./App"]
```

## Git Workflow

- Main branch: `main`
- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Commit messages: Use conventional commits (e.g., `feat:`, `fix:`, `docs:`)

## Useful Resources

- [Swift on Server](https://swiftonserver.com/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Package Manager](https://www.swift.org/documentation/package-manager/)
- [Swift NIO](https://github.com/apple/swift-nio)
