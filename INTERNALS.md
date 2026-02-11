# CL Client CLI Dart - Developer Documentation

Internal documentation for developers working on the Dart CLI codebase.

## Package Structure

### Dart Standard Structure

The CLI follows Dart package conventions:

```
cli_dart/
├── bin/
│   └── cli_dart.dart              # Entry point with CLI parsing
├── lib/
│   ├── cli_dart.dart              # Public exports
│   └── src/                       # Implementation (private)
│       ├── commands/
│       │   ├── login_command.dart
│       │   ├── logout_command.dart
│       │   └── store/             # Store subcommands
│       │       ├── store_command.dart
│       │       ├── list_command.dart
│       │       ├── upload_command.dart
│       │       ├── create_command.dart
│       │       ├── get_command.dart
│       │       ├── update_command.dart
│       │       ├── patch_command.dart
│       │       ├── delete_command.dart
│       │       ├── versions_command.dart
│       │       ├── intelligence_command.dart
│       │       └── face_command.dart
│       ├── common/
│       │   ├── config.dart        # CLIConfig, ServerPref
│       │   ├── cached_config.dart # Encryption/decryption
│       │   ├── context.dart       # CLIContext
│       │   ├── output.dart        # Output helpers
│       │   └── exceptions.dart    # Custom exceptions
│       ├── utils/
│       │   └── store_manager_factory.dart
│       └── version.dart
├── test/                          # Tests (unit + integration)
├── pubspec.yaml                   # Dependencies
└── analysis_options.yaml          # Linting rules
```

## Development

### Setup

```bash
# Navigate to CLI directory
cd apps/cli_dart

# Install dependencies
dart pub get

# Verify setup
dart analyze
```

### Running from Source

```bash
# Run CLI directly (no compilation)
dart run bin/cli_dart.dart [command] [args]

# Run with debugger
dart run --observe bin/cli_dart.dart [command] [args]

# Run specific command
dart run bin/cli_dart.dart store list
```

### Building

```bash
# Compile to native executable
dart compile exe bin/cli_dart.dart -o cli-dart

# Compile with optimizations
dart compile exe --target-os=linux bin/cli_dart.dart -o cli-dart
```

### Code Quality

```bash
# Type checking + linting
dart analyze

# Format code
dart format lib/ bin/ test/

# Run tests
dart test

# Run tests with coverage
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --report-on=lib
```

## Architecture

### Configuration Priority

**For Login Command:**
1. Load config file `~/.cl_client_config.json` (if exists)
2. Apply CLI flag overrides (username, password, URLs)
3. Prompt for missing credentials (if not --json and not --no-auth)
4. Validate credentials via login
5. Save complete config to cache

**For Other Commands:**
1. Load cached config (must exist and be valid)
2. If no cache, exit with error "Not logged in. Run: cli-dart login"
3. Apply global --json override if present
4. Use config for command execution

### Cache Encryption

**Implementation**:
- Algorithm: AES-GCM (authenticated encryption)
- Key derivation: SHA-256 of "cl-client:\<hostname>"
- Machine ID: `Platform.localHostname` (pure Dart, no Flutter)
- Format: `{"encrypted_config": "...", "iv": "...", "timestamp": ...}`
- Expiration: 6 hours (21600 seconds)
- File: `~/.cl_dart_client_cache`
- Permissions: 0o600 on Unix (chmod command)

**Code**:
```dart
// lib/src/common/cached_config.dart
String _getMachineId() {
  return Platform.localHostname; // Pure Dart
}

encrypt.Key _getEncryptionKey() {
  final machineId = _getMachineId();
  final keyMaterial = 'cl-client:$machineId';
  final hash = sha256.convert(utf8.encode(keyMaterial));
  return encrypt.Key.fromBase64(base64.encode(hash.bytes.sublist(0, 32)));
}
```

### Session Management

**Pattern**: Store session in CLIContext, cleanup in try-finally blocks.

```dart
// All store commands follow this pattern
Future<void> runStoreListCommand(ArgResults args, CLIContext context) async {
  final manager = await getStoreManager(context);
  try {
    final result = await manager.listEntities(...);
    if (!result.isSuccess) {
      outputError(context, result.error ?? 'Failed');
    }
    outputSdkResult(context, result.data);
  } finally {
    await context.cleanup();  // Closes session!
  }
}
```

**Critical**: Session cleanup must happen in all code paths (success, error, exception).

### CLI Parsing with args Package

**Structure**:
```dart
// bin/cli_dart.dart
final parser = ArgParser()
  ..addFlag('json', ...)
  ..addFlag('version', ...);

final loginCmd = parser.addCommand('login');
loginCmd.addOption('username', abbr: 'u', ...);
loginCmd.addOption('password', abbr: 'p', ...);

final storeCmd = parser.addCommand('store');
final listCmd = storeCmd.addCommand('list');
listCmd.addOption('page', defaultsTo: '1', ...);
```

**Subcommand Handling**:
```dart
switch (results.command?.name) {
  case 'login':
    await runLoginCommand(results.command!, globalJson);
    break;
  case 'store':
    await _handleStoreCommand(results.command!, globalJson);
    break;
}
```

### Output Formatting

**JSON Mode**:
```dart
void outputSdkResult(CLIContext context, dynamic data) {
  final json = (data as dynamic).toJson();
  print(jsonEncode(json));
}
```

**Human Mode**:
```dart
void outputSuccess(CLIContext context, String message) {
  print('✓ $message');
}
```

**Error Handling**:
```dart
void outputError(CLIContext context, String message) {
  if (context.config.outputJson) {
    print(jsonEncode({'status': 'failed', 'error': message}));
  } else {
    stderr.writeln('Error: $message');
  }
  exit(1);
}
```

## Testing

### Test Structure

```
test/
├── unit/
│   ├── common/
│   │   ├── config_test.dart
│   │   ├── cached_config_test.dart
│   │   └── context_test.dart
│   └── store/
│       └── list_test.dart
└── integration/
    ├── auth_test.dart
    └── store_test.dart
```

### Unit Tests (with mocktail)

```dart
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStoreManager extends Mock implements StoreManager {}

void main() {
  group('StoreListCommand', () {
    late MockStoreManager mockManager;

    setUp(() {
      mockManager = MockStoreManager();
    });

    test('lists entities successfully', () async {
      when(() => mockManager.listEntities(page: 1, pageSize: 20))
        .thenAnswer((_) async => StoreOperationResult(
          isSuccess: true,
          data: EntityListResponse(items: []),
        ));

      // Test command logic
    });
  });
}
```

### Integration Tests

```dart
@Tags(['integration'])
void main() {
  test('login and list entities', () async {
    // Requires CL_AUTH_URL, CL_STORE_URL environment variables
    // Requires running server
  }, tags: 'integration');
}
```

**Run Tests**:
```bash
# Unit tests only
dart test

# Skip integration tests
dart test -x integration

# Run integration tests
dart test -t integration
```

## Adding New Commands

### Step 1: Create Command File

```dart
// lib/src/commands/store/new_command.dart
import 'package:args/args.dart';
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

Future<void> runStoreNewCommand(ArgResults args, CLIContext context) async {
  final manager = await getStoreManager(context);
  try {
    final result = await manager.someMethod(...);
    if (!result.isSuccess) {
      outputError(context, result.error ?? 'Operation failed');
    }
    outputSdkResult(context, result.data);
  } finally {
    await context.cleanup();
  }
}
```

### Step 2: Export Command

```dart
// lib/cli_dart.dart
export 'src/commands/store/new_command.dart';
```

### Step 3: Register in Main

```dart
// bin/cli_dart.dart
final newCmd = storeCmd.addCommand('new');
newCmd.addOption('some-option', ...);

// In _handleStoreCommand:
case 'new':
  await runStoreNewCommand(args.command!, context);
  break;
```

### Step 4: Add Tests

```dart
// test/unit/store/new_command_test.dart
void main() {
  test('new command works', () async {
    // Test implementation
  });
}
```

## Common Patterns

### Async Resource Management

```dart
// Always use try-finally
final manager = await getStoreManager(context);
try {
  // Do work
} finally {
  await context.cleanup();  // Critical!
}
```

### Error Handling

```dart
// Check SDK results
if (!result.isSuccess || result.data == null) {
  outputError(context, result.error ?? 'Operation failed');
}
```

### Argument Parsing

```dart
// Required positional arguments
final rest = args.rest;
if (rest.isEmpty) {
  outputError(context, 'Entity ID required');
}

final entityId = int.tryParse(rest[0]);
if (entityId == null) {
  outputError(context, 'Invalid entity ID: ${rest[0]}');
}
```

## Dependencies

### Production

```yaml
dependencies:
  args: ^2.4.2           # CLI argument parsing
  path: ^1.9.0           # Path manipulation
  crypto: ^3.0.7         # SHA-256 hashing
  encrypt: ^5.0.3        # AES-GCM encryption
  cl_server_dart_client: # SDK
    path: ../../sdks/dartsdk
```

### Development

```yaml
dev_dependencies:
  test: ^1.24.3          # Testing framework
  mocktail: ^1.0.1       # Mocking library
  lints: ^3.0.0          # Linting rules
```

## Troubleshooting

### Compilation Errors

**Issue**: Flutter dependencies error
```
Error: Dart library 'dart:ui' is not available
```
**Solution**: Ensure no Flutter packages in dependencies. Use pure Dart alternatives.

### Runtime Errors

**Issue**: Authentication fails
```bash
# Clear cache and re-login
./cli-dart logout
./cli-dart login
```

**Issue**: Session not cleaned up
```bash
# Check for unawaited futures
dart analyze
# Look for unawaited_futures warnings
```

## Best Practices

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` before committing
- Add type annotations for public APIs
- Use descriptive variable names

### Error Handling

- Always check `result.isSuccess` before accessing `result.data`
- Provide helpful error messages
- Use `outputError()` for consistent error formatting

### Testing

- Write tests for all new commands
- Mock SDK interactions for unit tests
- Tag integration tests with `@Tags(['integration'])`
- Aim for >70% code coverage

### Documentation

- Update README.md for new commands
- Add examples for complex operations
- Document breaking changes
- Keep INTERNALS.md current

## Version History

- **1.0.0** - Initial release with login, logout, and store commands

## Support

- **User Documentation**: [README.md](README.md)
- **Python CLI**: [../cli_python/INTERNALS.md](../cli_python/INTERNALS.md)
- **Dart SDK**: [../../sdks/dartsdk/README.md](../../sdks/dartsdk/README.md)
