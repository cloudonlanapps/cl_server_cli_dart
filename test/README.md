# Tests for CLI Dart

This directory contains the test suite for the Dart CLI application. The tests are written using `dart test` and cover authentication, configuration management, caching, and store operations.

## Overview & Structure

The test suite is organized into two categories:

- **Unit tests** (`test/unit/`) — Test individual components with mocked dependencies (no server required)
- **Integration tests** (`test/integration/`) — Test against live CL Server services

## Prerequisites

- Dart SDK 3.0+
- Dependencies installed via `dart pub get`
- For integration tests: Running CL Server (Auth + Store + MQTT services)

## Running Tests

### Run All Tests

To run the entire test suite:

```bash
dart test
```

### Run Unit Tests Only

To run only unit tests (no server required):

```bash
dart test test/unit/
```

### Run Integration Tests Only

To run integration tests (requires running server):

```bash
dart test test/integration/ -t integration
```

### Skip Integration Tests

To run all tests except integration tests:

```bash
dart test -x integration
```

### Run Specific Test Files

To run tests from a specific file:

```bash
dart test test/unit/common/config_test.dart
dart test test/unit/store/list_test.dart
```

### Run Individual Tests

To run a specific test by name:

```bash
# Run tests matching a pattern
dart test --name "creates with default values"

# Run a specific test group
dart test --name "ServerPref"
```

### Coverage Options

```bash
# Run with coverage
dart test --coverage=coverage

# Generate coverage report
dart run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --report-on=lib

# View coverage in HTML (requires lcov tools)
genhtml coverage.lcov -o coverage/html
```

## Test Organization

### Unit Tests (test/unit/)

Unit tests use mocked dependencies and don't require a running server.

```
test/unit/
├── common/
│   ├── config_test.dart           # CLIConfig and ServerPref tests (14 tests)
│   ├── cached_config_test.dart    # Cache encryption and expiration (8 tests)
│   └── context_test.dart          # CLIContext and session cleanup (5 tests)
└── store/
    ├── list_test.dart             # Store list command tests (6 tests)
    └── utils_test.dart            # Store manager factory tests (4 tests)
```

**Total Unit Tests:** 37

### Integration Tests (test/integration/)

Integration tests require running CL Server services.

```
test/integration/
├── auth_test.dart                 # Authentication flow tests (5 tests)
└── store_test.dart                # Store CRUD operations (8 tests)
```

**Total Integration Tests:** 13

## Test Structure

The tests are organized into the following files:

| File | Description |
|------|-------------|
| `test/unit/common/config_test.dart` | Tests for CLIConfig and ServerPref (file loading, JSON serialization, defaults) |
| `test/unit/common/cached_config_test.dart` | Tests for encrypted cache (save, load, expiration, corruption handling) |
| `test/unit/common/context_test.dart` | Tests for CLIContext (session management, cleanup) |
| `test/unit/store/list_test.dart` | Tests for store list command (pagination, search, error handling) |
| `test/unit/store/utils_test.dart` | Tests for store manager factory (guest mode, authentication) |
| `test/integration/auth_test.dart` | Integration tests for login/logout flow |
| `test/integration/store_test.dart` | Integration tests for store CRUD operations |

## Service Requirements

Integration tests require **running CL Server services**:

```
Auth Service:     http://192.168.0.105:8010
Store Service:    http://192.168.0.105:8011
MQTT Broker:      mqtt://192.168.0.105:1883
```

### Starting Services

Refer to the main CL Server documentation for starting services. Integration tests expect services to be running at the addresses above (configurable via environment variables).

### Configuration for Integration Tests

Integration tests read from the shared config file `~/.cl_client_config.json`:

```json
{
  "server_pref": {
    "auth_url": "http://192.168.0.105:8010",
    "compute_url": "http://192.168.0.105:8012",
    "store_url": "http://192.168.0.105:8011",
    "mqtt_url": "mqtt://192.168.0.105:1883"
  },
  "username": "admin"
}
```

**Note:** Password is not stored in the config file for security. Integration tests use `admin` as the default password.

If the config file doesn't exist, tests fall back to default URLs (192.168.0.105).

Run integration tests:

```bash
dart test test/integration/ -t integration
```

## Test Details

### Unit Tests

**config_test.dart** (14 tests)
- ServerPref: default values, custom values, JSON serialization, copyWith
- CLIConfig: creation, JSON conversion, file loading, ServerConfig conversion

**cached_config_test.dart** (8 tests)
- Save/load config to/from encrypted cache
- 6-hour expiration handling
- Corrupted cache recovery
- File permissions (Unix)
- Machine-specific encryption keys

**context_test.dart** (5 tests)
- CLIContext creation with config
- Session storage and cleanup
- Multiple cleanup calls safety

**list_test.dart** (6 tests)
- List entities with default/custom pagination
- Search query support
- Error handling
- Argument parsing

**utils_test.dart** (4 tests)
- Guest mode manager creation
- Authenticated manager requirements
- Server URL configuration

### Integration Tests

**auth_test.dart** (5 tests)
- Login with valid/invalid credentials
- Store manager creation after login
- Cache persistence across sessions
- Logout clears cache

**store_test.dart** (8 tests)
- List entities
- Create/get/update/patch/delete entities
- Version history
- Guest mode authentication requirement

## Configuration

Test configuration uses standard Dart test package settings. Integration tests are tagged with `@Tags(['integration'])` to allow selective execution.

**Test Tags:**
- `integration` - Marks tests that require running services

## Troubleshooting

### Tests Fail with "Not logged in"

Integration tests require:
1. Valid config file at `~/.cl_client_config.json` with server URLs and username
2. Password is hardcoded as `admin` in tests (for security, not stored in config file)

If tests fail, verify your config file exists and has correct server URLs.

### Integration Tests Time Out

Ensure CL Server services are running and accessible at the configured URLs:

```bash
# Check auth service
curl http://192.168.0.105:8010/health

# Check store service
curl http://192.168.0.105:8011/health
```

### Cache-Related Test Failures

Some cache tests modify `~/.cl_dart_client_cache`. If tests fail, manually clear the cache:

```bash
rm ~/.cl_dart_client_cache
```

### Mock Errors in Unit Tests

Ensure `mocktail` package is properly installed:

```bash
dart pub get
```

## Quick Reference

```bash
# All tests
dart test

# Unit tests only (fast, no server)
dart test test/unit/

# Integration tests only (requires server)
dart test test/integration/ -t integration

# Skip integration tests
dart test -x integration

# Specific test file
dart test test/unit/common/config_test.dart

# Verbose output
dart test --reporter=expanded

# With coverage
dart test --coverage=coverage
```
