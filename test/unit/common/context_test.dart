import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cli_dart/src/common/config.dart';
import 'package:cli_dart/src/common/context.dart';
import 'package:cl_server_dart_client/cl_server_dart_client.dart';

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  group('CLIContext', () {
    test('creates with config', () {
      const config = CLIConfig(serverPref: ServerPref());
      final context = CLIContext(config: config);

      expect(context.config, config);
      expect(context.session, isNull);
    });

    test('creates with config and session', () {
      const config = CLIConfig(serverPref: ServerPref());
      final session = MockSessionManager();
      final context = CLIContext(config: config, session: session);

      expect(context.config, config);
      expect(context.session, session);
    });

    test('cleanup closes session when present', () async {
      const config = CLIConfig(serverPref: ServerPref());
      final session = MockSessionManager();
      final context = CLIContext(config: config, session: session);

      when(() => session.close()).thenAnswer((_) async => {});

      await context.cleanup();

      verify(() => session.close()).called(1);
      expect(context.session, isNull);
    });

    test('cleanup does nothing when session is null', () async {
      const config = CLIConfig(serverPref: ServerPref());
      final context = CLIContext(config: config);

      // Should not throw
      await context.cleanup();
      expect(context.session, isNull);
    });

    test('cleanup can be called multiple times', () async {
      const config = CLIConfig(serverPref: ServerPref());
      final session = MockSessionManager();
      final context = CLIContext(config: config, session: session);

      when(() => session.close()).thenAnswer((_) async => {});

      await context.cleanup();
      await context.cleanup(); // Second call should be safe

      // First call closes session, second does nothing
      verify(() => session.close()).called(1);
    });
  });
}
