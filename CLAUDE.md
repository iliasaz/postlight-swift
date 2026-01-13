# CLAUDE.md - AI Assistant Guide for postlight-swift

This document provides guidance for AI assistants working with this server-side Swift project using Hummingbird and Swift 6 concurrency.

## Project Overview

This is a server-side Swift project built with:
- **Hummingbird 2.x** - Lightweight, flexible HTTP server framework
- **Swift 6.x** - With modern structured concurrency
- **Swift Package Manager** - For dependency management

## Project Structure

```
postlight-swift/
├── Package.swift              # Swift package manifest
├── Sources/
│   └── App/
│       ├── App.swift          # Entry point with @main
│       ├── Application+build.swift  # Application configuration
│       ├── Controllers/       # Route handlers grouped by domain
│       ├── Models/            # Data models and DTOs
│       ├── Middleware/        # Custom middleware
│       ├── Services/          # Business logic layer
│       └── Extensions/        # Swift extensions
├── Tests/
│   └── AppTests/              # Unit and integration tests
├── Resources/                 # Static files, templates
└── CLAUDE.md
```

## Build and Run Commands

```bash
# Build the project
swift build

# Run the server (development)
swift run App

# Run with specific options
swift run App --hostname 0.0.0.0 --port 8080

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
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
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

## Hummingbird 2 Patterns

### Application Setup

```swift
// Sources/App/App.swift
import ArgumentParser
import Hummingbird

@main
struct App: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    func run() async throws {
        let app = try await buildApplication(
            configuration: .init(
                address: .hostname(hostname, port: port)
            )
        )
        try await app.runService()
    }
}
```

### Application Configuration

```swift
// Sources/App/Application+build.swift
import Hummingbird

func buildApplication(
    configuration: ApplicationConfiguration
) async throws -> some ApplicationProtocol {
    let router = Router()

    // Add middleware
    router.middlewares.add(LogRequestsMiddleware(.info))

    // Configure routes
    configureRoutes(router)

    return Application(
        router: router,
        configuration: configuration
    )
}
```

### Request Context Pattern

```swift
// Custom request context for dependency injection
struct AppRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    let database: DatabaseService
    let logger: Logger

    init(source: Source) {
        self.coreContext = .init(source: source)
        self.database = source.database
        self.logger = source.logger
    }
}
```

### Route Handlers

```swift
// Controllers/UserController.swift
import Hummingbird

struct UserController {
    func configure(_ router: Router<AppRequestContext>) {
        let users = router.group("users")
        users.get(use: list)
        users.get(":id", use: get)
        users.post(use: create)
        users.put(":id", use: update)
        users.delete(":id", use: delete)
    }

    @Sendable
    func list(_ request: Request, context: AppRequestContext) async throws -> [UserDTO] {
        try await context.database.users.all()
    }

    @Sendable
    func get(_ request: Request, context: AppRequestContext) async throws -> UserDTO {
        guard let id = context.parameters.get("id", as: UUID.self) else {
            throw HTTPError(.badRequest, message: "Invalid user ID")
        }
        guard let user = try await context.database.users.find(id) else {
            throw HTTPError(.notFound, message: "User not found")
        }
        return user
    }

    @Sendable
    func create(_ request: Request, context: AppRequestContext) async throws -> Response {
        let input = try await request.decode(as: CreateUserInput.self, context: context)
        let user = try await context.database.users.create(input)
        return Response(status: .created, body: .init(data: user.encode()))
    }
}
```

### Middleware

```swift
// Middleware/AuthMiddleware.swift
import Hummingbird

struct AuthMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        guard let token = request.headers.bearer else {
            throw HTTPError(.unauthorized)
        }

        // Validate token
        guard try await validateToken(token) else {
            throw HTTPError(.unauthorized)
        }

        return try await next(request, context)
    }
}
```

## Code Style Guidelines

### Naming Conventions

- **Types**: `PascalCase` (e.g., `UserController`, `DatabaseService`)
- **Functions/Methods**: `camelCase` (e.g., `fetchUser`, `validateToken`)
- **Variables**: `camelCase` (e.g., `userId`, `requestContext`)
- **Constants**: `camelCase` (e.g., `defaultTimeout`, `maxRetries`)
- **File names**: Match primary type (e.g., `UserController.swift`)
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
enum AppError: Error, HTTPResponseError {
    case userNotFound(UUID)
    case invalidInput(String)
    case databaseError(Error)

    var status: HTTPResponse.Status {
        switch self {
        case .userNotFound: return .notFound
        case .invalidInput: return .badRequest
        case .databaseError: return .internalServerError
        }
    }

    var body: some ResponseEncodable {
        ErrorResponse(message: self.localizedDescription)
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

### Integration Tests

```swift
import Hummingbird
import HummingbirdTesting
import XCTest
@testable import App

final class UserControllerTests: XCTestCase {
    func testGetUserReturns200() async throws {
        let app = try await buildApplication(
            configuration: .init(address: .hostname("localhost", port: 0))
        )

        try await app.test(.router) { client in
            try await client.execute(
                uri: "/users/\(testUserId)",
                method: .get
            ) { response in
                XCTAssertEqual(response.status, .ok)
            }
        }
    }
}
```

## Common Dependencies

```swift
// Typical server-side Swift dependencies
.package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
.package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.0.0"),
.package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0"),
.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
.package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
.package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
```

## Environment Configuration

```swift
// Use environment variables for configuration
struct Config {
    let databaseURL: String
    let jwtSecret: String
    let port: Int

    init() throws {
        guard let dbURL = Environment.get("DATABASE_URL") else {
            throw ConfigError.missingEnvironmentVariable("DATABASE_URL")
        }
        self.databaseURL = dbURL
        self.jwtSecret = Environment.get("JWT_SECRET") ?? "development-secret"
        self.port = Environment.get("PORT").flatMap(Int.init) ?? 8080
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
EXPOSE 8080
CMD ["./App", "--hostname", "0.0.0.0", "--port", "8080"]
```

## Git Workflow

- Main branch: `main`
- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Commit messages: Use conventional commits (e.g., `feat:`, `fix:`, `docs:`)

## Useful Resources

- [Hummingbird Documentation](https://hummingbird.codes/)
- [Hummingbird Examples](https://github.com/hummingbird-project/hummingbird-examples)
- [Swift on Server](https://swiftonserver.com/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
