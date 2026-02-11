# CL Client CLI - Dart

Command-line interface for the CL Server. Dart implementation providing the same functionality as `cli-python`.

**Language:** Dart
**Authentication Method:** Login with cache (6-hour expiration)
**SDK:** cl_server_dart_client

> **For Developers:** See [INTERNALS.md](INTERNALS.md) for architecture and development guide.

## Features

- 🔐 **Secure Login**: Encrypted credential caching with 6-hour expiration
- 📦 **Store Management**: Full CRUD operations for entities and collections
- 🚀 **Fast Native Binary**: Compiled Dart binary for optimal performance
- 📊 **JSON Output**: Machine-parseable output with `--json` flag
- 🔄 **Guest Mode**: No-auth mode for public instances

## Installation

### Prerequisites

- Dart SDK 3.0+ ([installation guide](https://dart.dev/get-dart))
- Running CL Server components (Auth, Store, MQTT)

### Build from Source

```bash
# Navigate to cli_dart directory
cd apps/cli_dart

# Install dependencies
dart pub get

# Compile to native binary
dart compile exe bin/cli_dart.dart -o cli-dart

# Verify installation
./cli-dart --version
```

### Add to PATH (Optional)

```bash
# Move binary to system path
sudo mv cli-dart /usr/local/bin/
cli-dart --help
```

## Quick Start

The CLI uses a login-once approach. Login with your credentials once, then use all commands without repeating credentials.

### Basic Usage

**Login first (one-time):**
```bash
# Login with all configuration
./cli-dart login \
  --username admin \
  --password mypass \
  --auth-url http://192.168.0.105:8010 \
  --store-url http://192.168.0.105:8011 \
  --mqtt-url mqtt://192.168.0.105:1883

# Or use short flags
./cli-dart login -u admin -p mypass \
  --auth-url http://192.168.0.105:8010 \
  --store-url http://192.168.0.105:8011
```

**Then use commands (no credentials needed):**
```bash
# All commands use cached configuration
./cli-dart store list
./cli-dart store upload photo.jpg --label "My Photo"
./cli-dart store get 123
```

**With config file (recommended):**
```bash
# One-time setup: create config file
echo '{
  "server_pref": {
    "auth_url": "http://192.168.0.105:8010",
    "compute_url": "http://192.168.0.105:8012",
    "store_url": "http://192.168.0.105:8011",
    "mqtt_url": "mqtt://192.168.0.105:1883"
  }
}' > ~/.cl_client_config.json

# Login once (URLs loaded from config, prompt for credentials)
./cli-dart login
Username: admin
Password: ****

# Use commands without repeating credentials
./cli-dart store list
./cli-dart store upload photo.jpg
```

## Available Commands

### Session Management

**Login**
```bash
# Login with all credentials and URLs
./cli-dart login --username admin --password mypass \
  --auth-url http://192.168.0.105:8010 \
  --store-url http://192.168.0.105:8011

# Guest mode (no authentication)
./cli-dart login --no-auth --store-url http://192.168.0.105:8011
```

**Logout**
```bash
# Clear cached configuration and credentials
./cli-dart logout
```

### Store Management

**List Entities**
```bash
# List all entities
./cli-dart store list

# With pagination
./cli-dart store list --page 2 --page-size 50

# Search
./cli-dart store list --search "vacation"

# Save to file
./cli-dart store list --output entities.json
```

**Upload Media**
```bash
# Upload single file
./cli-dart store upload photo.jpg --label "Beach Sunset"

# Upload with description and parent
./cli-dart store upload photo.jpg \
  --label "Vacation" \
  --description "Summer 2024" \
  --parent-id 5

# Upload directory recursively
./cli-dart store upload photos/ --recursive --yes
```

**Create Collection**
```bash
# Create empty collection
./cli-dart store create --label "My Collection"

# With description and parent
./cli-dart store create \
  --label "Travel Photos" \
  --description "Photos from trips" \
  --parent-id 10
```

**Get Entity**
```bash
./cli-dart store get 123
```

**Update Entity**
```bash
./cli-dart store update 123 --label "New Label"
./cli-dart store update 123 --label "Updated" --description "New description"
```

**Patch Entity**
```bash
./cli-dart store patch 123 --label "Partial Update"
```

**Delete Entity**
```bash
./cli-dart store delete 123
```

**Get Versions**
```bash
./cli-dart store versions 123
```

**Get Intelligence Data**
```bash
./cli-dart store intelligence 123
```

**Delete Face**
```bash
./cli-dart store face delete 456
```

## Configuration

### Configuration File (Optional)

Create `~/.cl_client_config.json` to avoid specifying URLs every time:

```json
{
  "server_pref": {
    "auth_url": "http://192.168.0.105:8010",
    "compute_url": "http://192.168.0.105:8012",
    "store_url": "http://192.168.0.105:8011",
    "mqtt_url": "mqtt://192.168.0.105:1883"
  }
}
```

**Note**: Credentials are never stored in the config file. They're provided during login and cached securely.

### Configuration Caching

After running `cli-dart login`, your configuration is cached securely:

- **What's cached**: Full configuration (URLs, credentials, settings)
- **Encryption**: AES-GCM encryption
- **Expiration**: 6 hours
- **Storage**: `~/.cl_dart_client_cache` (permissions: 0o600)
- **Machine-specific**: Encryption key derived from hostname
- **Auto-clear**: Cache cleared automatically on expiration or auth failure

**Clear cache manually**:
```bash
./cli-dart logout
```

## Output Formats

### Human-Readable (Default)

```
✓ Logged in as admin
```

### JSON Mode

```bash
./cli-dart --json store list
{"status":"success","data":[...]}
```

## Error Handling

### Authentication Errors

```bash
$ ./cli-dart store list
Error: Not logged in. Run: cli-dart login
```

### Invalid Commands

```bash
$ ./cli-dart store get
Error: Entity ID required
```

## Differences from cli-python

- **Same config file**: Shares `~/.cl_client_config.json` (read-only)
- **Different cache**: Uses `~/.cl_dart_client_cache` (Dart-specific encryption)
- **Same API**: All commands work identically
- **Native binary**: Compiled executable for better performance

## Development

### Build from Source

```bash
cd apps/cli_dart
dart pub get
dart compile exe bin/cli_dart.dart -o cli-dart
```

### Run Without Compiling

```bash
dart run bin/cli_dart.dart --help
```

### Code Quality

```bash
# Analyze code
dart analyze

# Format code
dart format lib/ bin/

# Run tests
dart test
```

## Troubleshooting

### Command Not Found

```bash
# Use full path
./cli-dart --help

# Or add to PATH
export PATH="$PATH:$(pwd)"
```

### Cache Expired

```bash
# Login again
./cli-dart login
```

### Connection Refused

```bash
# Check server is running
curl http://192.168.0.105:8011/health
```

## Support

- **Documentation**: See this file and INTERNALS.md
- **Issues**: Report at project issue tracker
- **Python CLI**: See [../cli_python/README.md](../cli_python/README.md)

## Version

- **CLI Version**: 1.0.0
- **Dart SDK**: 3.0+
- **SDK Version**: cl_server_dart_client

## License

MIT License - see LICENSE file for details.
