@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:cli_dart/src/common/config.dart';
import 'package:cli_dart/src/common/cached_config.dart';
import 'package:cl_server_dart_client/cl_server_dart_client.dart';

/// Integration tests for authentication
/// Requires:
/// - Running CL Server
/// - Config file: ~/.cl_client_config.json (shared with Python CLI)
/// - Password: admin (not stored in config for security)
void main() {
  late ServerConfig serverConfig;
  late String username;
  late String password;

  setUpAll(() async {
    // Load from config file (shared with Python CLI)
    final config = await CLIConfig.loadFromFile();

    if (config != null) {
      // Use config file settings
      serverConfig = config.toServerConfig();
      username = config.username ?? 'admin';
      password = 'admin'; // Password not stored in config
    } else {
      // Fallback to defaults
      serverConfig = const ServerConfig(
        authUrl: 'http://192.168.0.105:8010',
        computeUrl: 'http://192.168.0.105:8012',
        storeUrl: 'http://192.168.0.105:8011',
        mqttUrl: 'mqtt://192.168.0.105:1883',
      );
      username = 'admin';
      password = 'admin';
    }
  });

  tearDown(() async {
    // Clean up cache after each test
    await clearConfigCache();
  });

  group('Authentication Integration', () {
    test('login with valid credentials succeeds', () async {
      final session = SessionManager(serverConfig: serverConfig);

      try {
        final token = await session.login(username, password);
        expect(token, isNotNull);
        expect(token.accessToken, isNotEmpty);
        expect(session.isAuthenticated, true);
      } finally {
        await session.close();
      }
    });

    test('login with invalid credentials fails', () async {
      final session = SessionManager(serverConfig: serverConfig);

      try {
        await session.login('invalid', 'wrong');
        fail('Should have thrown AuthenticationError');
      } on AuthenticationError catch (e) {
        expect(e.message, contains('Authentication failed'));
      } finally {
        await session.close();
      }
    });

    test('session manager creates store manager after login', () async {
      final session = SessionManager(serverConfig: serverConfig);

      try {
        await session.login(username, password);
        final storeManager = session.createStoreManager();
        expect(storeManager, isNotNull);
      } finally {
        await session.close();
      }
    });

    test('cache persists login configuration', () async {
      final config = CLIConfig(
        serverPref: const ServerPref(),
        username: username,
        password: password,
      );

      // Save to cache
      await saveConfigToCache(config);

      // Load from cache
      final loaded = await loadConfigFromCache();
      expect(loaded, isNotNull);
      expect(loaded!.username, username);
      expect(loaded.password, password);
      expect(loaded.serverPref.authUrl, serverConfig.authUrl);
    });

    test('logout clears cache', () async {
      final config = CLIConfig(
        serverPref: ServerPref(
          authUrl: serverConfig.authUrl,
          storeUrl: serverConfig.storeUrl,
        ),
        username: username,
        password: password,
      );

      // Save to cache
      await saveConfigToCache(config);

      // Verify cache exists
      var loaded = await loadConfigFromCache();
      expect(loaded, isNotNull);

      // Clear cache (logout)
      await clearConfigCache();

      // Verify cache is cleared
      loaded = await loadConfigFromCache();
      expect(loaded, isNull);
    });
  }, tags: 'integration');
}
