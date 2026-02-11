import 'dart:io';
import 'package:args/args.dart';
import 'package:cl_server_dart_client/cl_server_dart_client.dart';
import '../common/cached_config.dart';
import '../common/config.dart';
import '../common/context.dart';
import '../common/output.dart';

/// Execute login command
Future<void> runLoginCommand(ArgResults args, bool globalJson) async {
  // Load base config from file if exists
  CLIConfig config =
      await CLIConfig.loadFromFile() ?? CLIConfig.defaultConfig();

  // Apply CLI overrides for server URLs
  if (args.wasParsed('auth-url') ||
      args.wasParsed('compute-url') ||
      args.wasParsed('store-url') ||
      args.wasParsed('mqtt-url')) {
    config = config.copyWith(
      serverPref: config.serverPref.copyWith(
        authUrl: args['auth-url'] as String? ?? config.serverPref.authUrl,
        computeUrl:
            args['compute-url'] as String? ?? config.serverPref.computeUrl,
        storeUrl: args['store-url'] as String? ?? config.serverPref.storeUrl,
        mqttUrl: args['mqtt-url'] as String? ?? config.serverPref.mqttUrl,
      ),
    );
  }

  // Handle no-auth flag
  final noAuth = args['no-auth'] as bool? ?? false;
  if (noAuth) {
    config = config.copyWith(noAuth: true);
    // Save guest mode config to cache
    await saveConfigToCache(config);
    final context = CLIContext(
      config: config.copyWith(
        outputJson: args['json'] as bool? ?? globalJson,
      ),
    );
    outputSuccess(context, 'Logged in (guest mode)');
    return;
  }

  // Get username and password
  String? username = args['username'] as String? ?? config.username;
  String? password = args['password'] as String?;

  // Check if we're in JSON mode (no interactive prompts)
  final jsonMode = args['json'] as bool? ?? globalJson;

  // Prompt for missing credentials if interactive
  if (!jsonMode) {
    if (username == null || username.isEmpty) {
      stdout.write('Username: ');
      username = stdin.readLineSync();
    }

    if (password == null || password.isEmpty) {
      stdout.write('Password: ');
      // Note: stdin.echoMode is not available, so password will be visible
      // In production, consider using a package like 'io' or 'console' for hidden input
      password = stdin.readLineSync();
    }
  }

  // Validate we have credentials
  if (username == null || username.isEmpty || password == null || password.isEmpty) {
    final context = CLIContext(
      config: config.copyWith(outputJson: jsonMode),
    );
    outputError(context, 'Username and password required for login');
    return;
  }

  // Update config with credentials
  config = config.copyWith(
    username: username,
    password: password,
    noAuth: false,
  );

  // Validate credentials by attempting login
  SessionManager? session;
  try {
    session = SessionManager(serverConfig: config.toServerConfig());
    await session.login(username, password);

    // Login successful, save config to cache
    await saveConfigToCache(config);

    final context = CLIContext(
      config: config.copyWith(outputJson: jsonMode),
    );
    outputSuccess(context, 'Logged in as $username');
  } on AuthenticationError catch (e) {
    final context = CLIContext(
      config: config.copyWith(outputJson: jsonMode),
    );
    outputError(context, 'Authentication failed: ${e.message}');
  } catch (e) {
    final context = CLIContext(
      config: config.copyWith(outputJson: jsonMode),
    );
    outputError(context, 'Login failed: $e');
  } finally {
    if (session != null) {
      await session.close();
    }
  }
}
