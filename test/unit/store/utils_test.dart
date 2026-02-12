import 'package:test/test.dart';
import 'package:cli_dart/src/common/config.dart';
import 'package:cli_dart/src/common/context.dart';

void main() {
  group('StoreManagerFactory', () {
    test('creates guest manager when noAuth is true', () {
      const config = CLIConfig(
        serverPref: ServerPref(),
        noAuth: true,
      );
      final context = CLIContext(config: config);

      expect(context.config.noAuth, true);
      expect(context.config.username, isNull);
      expect(context.config.password, isNull);
    });

    test('creates guest manager when credentials are missing', () {
      const config = CLIConfig(
        serverPref: ServerPref(),
        noAuth: false,
      );
      final context = CLIContext(config: config);

      expect(context.config.username, isNull);
      expect(context.config.password, isNull);
    });

    test('requires authentication when credentials present', () {
      const config = CLIConfig(
        serverPref: ServerPref(),
        username: 'admin',
        password: 'pass',
        noAuth: false,
      );
      final context = CLIContext(config: config);

      expect(context.config.username, isNotNull);
      expect(context.config.password, isNotNull);
      expect(context.config.noAuth, false);
    });

    test('context stores server URLs correctly', () {
      const config = CLIConfig(
        serverPref: ServerPref(
          storeUrl: 'http://test:8011',
          mqttUrl: 'mqtt://test:1883',
        ),
      );
      final context = CLIContext(config: config);

      expect(context.config.serverPref.storeUrl, 'http://test:8011');
      expect(context.config.serverPref.mqttUrl, 'mqtt://test:1883');
    });
  });
}
