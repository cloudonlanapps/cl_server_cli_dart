import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:cli_dart/src/common/config.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ServerPref', () {
    test('creates with default values', () {
      const serverPref = ServerPref();
      expect(serverPref.authUrl, 'http://192.168.0.105:8010');
      expect(serverPref.computeUrl, 'http://192.168.0.105:8012');
      expect(serverPref.storeUrl, 'http://192.168.0.105:8011');
      expect(serverPref.mqttUrl, 'mqtt://192.168.0.105:1883');
    });

    test('creates with custom values', () {
      const serverPref = ServerPref(
        authUrl: 'http://custom:8010',
        computeUrl: 'http://custom:8012',
        storeUrl: 'http://custom:8011',
        mqttUrl: 'mqtt://custom:1883',
      );
      expect(serverPref.authUrl, 'http://custom:8010');
      expect(serverPref.computeUrl, 'http://custom:8012');
      expect(serverPref.storeUrl, 'http://custom:8011');
      expect(serverPref.mqttUrl, 'mqtt://custom:1883');
    });

    test('converts to JSON correctly', () {
      const serverPref = ServerPref(authUrl: 'http://test:8010');
      final json = serverPref.toJson();
      expect(json['auth_url'], 'http://test:8010');
      expect(json['compute_url'], 'http://192.168.0.105:8012');
      expect(json['store_url'], 'http://192.168.0.105:8011');
      expect(json['mqtt_url'], 'mqtt://192.168.0.105:1883');
    });

    test('creates from JSON correctly', () {
      final json = {
        'auth_url': 'http://test:8010',
        'compute_url': 'http://test:8012',
        'store_url': 'http://test:8011',
        'mqtt_url': 'mqtt://test:1883',
      };
      final serverPref = ServerPref.fromJson(json);
      expect(serverPref.authUrl, 'http://test:8010');
      expect(serverPref.computeUrl, 'http://test:8012');
      expect(serverPref.storeUrl, 'http://test:8011');
      expect(serverPref.mqttUrl, 'mqtt://test:1883');
    });

    test('copyWith updates specified fields', () {
      const serverPref = ServerPref();
      final updated = serverPref.copyWith(authUrl: 'http://new:8010');
      expect(updated.authUrl, 'http://new:8010');
      expect(updated.computeUrl, serverPref.computeUrl);
      expect(updated.storeUrl, serverPref.storeUrl);
      expect(updated.mqttUrl, serverPref.mqttUrl);
    });
  });

  group('CLIConfig', () {
    test('creates with required server pref', () {
      const config = CLIConfig(serverPref: ServerPref());
      expect(config.serverPref, isNotNull);
      expect(config.username, isNull);
      expect(config.password, isNull);
      expect(config.noAuth, false);
      expect(config.outputJson, false);
    });

    test('creates with all fields', () {
      const config = CLIConfig(
        serverPref: ServerPref(),
        username: 'admin',
        password: 'pass',
        noAuth: true,
        outputJson: true,
      );
      expect(config.username, 'admin');
      expect(config.password, 'pass');
      expect(config.noAuth, true);
      expect(config.outputJson, true);
    });

    test('converts to JSON correctly', () {
      const config = CLIConfig(
        serverPref: ServerPref(),
        username: 'admin',
        password: 'secret',
        noAuth: false,
        outputJson: true,
      );
      final json = config.toJson();
      expect(json['server_pref'], isNotNull);
      expect(json['username'], 'admin');
      expect(json['password'], 'secret');
      expect(json['no_auth'], false);
      expect(json['output_json'], true);
    });

    test('creates from JSON correctly', () {
      final json = {
        'server_pref': {
          'auth_url': 'http://test:8010',
          'compute_url': 'http://test:8012',
          'store_url': 'http://test:8011',
          'mqtt_url': 'mqtt://test:1883',
        },
        'username': 'testuser',
        'password': 'testpass',
        'no_auth': false,
        'output_json': true,
      };
      final config = CLIConfig.fromJson(json);
      expect(config.username, 'testuser');
      expect(config.password, 'testpass');
      expect(config.noAuth, false);
      expect(config.outputJson, true);
      expect(config.serverPref.authUrl, 'http://test:8010');
    });

    test('converts to ServerConfig correctly', () {
      const config = CLIConfig(serverPref: ServerPref());
      final serverConfig = config.toServerConfig();
      expect(serverConfig.authUrl, config.serverPref.authUrl);
      expect(serverConfig.computeUrl, config.serverPref.computeUrl);
      expect(serverConfig.storeUrl, config.serverPref.storeUrl);
      expect(serverConfig.mqttUrl, config.serverPref.mqttUrl);
    });

    test('copyWith updates specified fields', () {
      const config = CLIConfig(
        serverPref: ServerPref(),
        username: 'admin',
      );
      final updated = config.copyWith(
        password: 'newpass',
        outputJson: true,
      );
      expect(updated.username, 'admin');
      expect(updated.password, 'newpass');
      expect(updated.outputJson, true);
    });

    test('loads from file when file exists', () async {
      // Create temporary config file
      final tempDir = await Directory.systemTemp.createTemp('cli_dart_test');
      final configPath = path.join(tempDir.path, 'test_config.json');
      final configData = {
        'server_pref': {
          'auth_url': 'http://test:8010',
          'store_url': 'http://test:8011',
        },
        'username': 'fileuser',
      };
      await File(configPath).writeAsString(jsonEncode(configData));

      final config = await CLIConfig.loadFromFile(configPath);
      expect(config, isNotNull);
      expect(config!.username, 'fileuser');
      expect(config.serverPref.authUrl, 'http://test:8010');

      // Cleanup
      await tempDir.delete(recursive: true);
    });

    test('returns null when file does not exist', () async {
      final config = await CLIConfig.loadFromFile('/nonexistent/config.json');
      expect(config, isNull);
    });

    test('default config has default server pref', () {
      final config = CLIConfig.defaultConfig();
      expect(config.serverPref.authUrl, 'http://192.168.0.105:8010');
      expect(config.username, isNull);
      expect(config.password, isNull);
    });
  });
}
