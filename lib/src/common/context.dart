import 'package:cl_server_dart_client/cl_server_dart_client.dart';
import 'config.dart';

/// CLI execution context containing configuration and session
class CLIContext {
  CLIContext({required this.config, this.session});

  final CLIConfig config;
  SessionManager? session;

  /// Clean up resources (close session)
  Future<void> cleanup() async {
    if (session != null) {
      await session!.close();
      session = null;
    }
  }
}
