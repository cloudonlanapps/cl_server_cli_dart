import 'package:cl_server_dart_client/cl_server_dart_client.dart';
import '../common/context.dart';

/// Get StoreManager (guest mode or authenticated)
Future<StoreManager> getStoreManager(CLIContext context) async {
  // Guest mode if no auth or no credentials
  if (context.config.noAuth ||
      context.config.username == null ||
      context.config.password == null) {
    return StoreManager.guest(
      baseUrl: context.config.serverPref.storeUrl,
      mqttUrl: context.config.serverPref.mqttUrl,
    );
  }

  // Authenticated mode
  final session = SessionManager(
    serverConfig: context.config.toServerConfig(),
  );

  await session.login(
    context.config.username!,
    context.config.password!,
  );

  // Store session for cleanup
  context.session = session;

  return session.createStoreManager();
}
