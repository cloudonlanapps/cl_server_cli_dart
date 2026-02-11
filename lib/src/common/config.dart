import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cl_server_dart_client/cl_server_dart_client.dart';

/// Server preference configuration
class ServerPref {
  const ServerPref({
    this.authUrl = 'http://192.168.0.105:8010',
    this.computeUrl = 'http://192.168.0.105:8012',
    this.storeUrl = 'http://192.168.0.105:8011',
    this.mqttUrl = 'mqtt://192.168.0.105:1883',
  });

  final String authUrl;
  final String computeUrl;
  final String storeUrl;
  final String mqttUrl;

  factory ServerPref.fromJson(Map<String, dynamic> json) {
    return ServerPref(
      authUrl: json['auth_url'] as String? ?? 'http://192.168.0.105:8010',
      computeUrl: json['compute_url'] as String? ?? 'http://192.168.0.105:8012',
      storeUrl: json['store_url'] as String? ?? 'http://192.168.0.105:8011',
      mqttUrl: json['mqtt_url'] as String? ?? 'mqtt://192.168.0.105:1883',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auth_url': authUrl,
      'compute_url': computeUrl,
      'store_url': storeUrl,
      'mqtt_url': mqttUrl,
    };
  }

  ServerPref copyWith({
    String? authUrl,
    String? computeUrl,
    String? storeUrl,
    String? mqttUrl,
  }) {
    return ServerPref(
      authUrl: authUrl ?? this.authUrl,
      computeUrl: computeUrl ?? this.computeUrl,
      storeUrl: storeUrl ?? this.storeUrl,
      mqttUrl: mqttUrl ?? this.mqttUrl,
    );
  }
}

/// CLI configuration
class CLIConfig {
  const CLIConfig({
    required this.serverPref,
    this.username,
    this.password,
    this.noAuth = false,
    this.outputJson = false,
  });

  final ServerPref serverPref;
  final String? username;
  final String? password;
  final bool noAuth;
  final bool outputJson;

  factory CLIConfig.fromJson(Map<String, dynamic> json) {
    return CLIConfig(
      serverPref: json.containsKey('server_pref')
          ? ServerPref.fromJson(json['server_pref'] as Map<String, dynamic>)
          : const ServerPref(),
      username: json['username'] as String?,
      password: json['password'] as String?,
      noAuth: json['no_auth'] as bool? ?? false,
      outputJson: json['output_json'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_pref': serverPref.toJson(),
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      'no_auth': noAuth,
      'output_json': outputJson,
    };
  }

  /// Convert to SDK ServerConfig
  ServerConfig toServerConfig() {
    return ServerConfig(
      authUrl: serverPref.authUrl,
      computeUrl: serverPref.computeUrl,
      storeUrl: serverPref.storeUrl,
      mqttUrl: serverPref.mqttUrl,
    );
  }

  CLIConfig copyWith({
    ServerPref? serverPref,
    String? username,
    String? password,
    bool? noAuth,
    bool? outputJson,
  }) {
    return CLIConfig(
      serverPref: serverPref ?? this.serverPref,
      username: username ?? this.username,
      password: password ?? this.password,
      noAuth: noAuth ?? this.noAuth,
      outputJson: outputJson ?? this.outputJson,
    );
  }

  /// Load configuration from file
  static Future<CLIConfig?> loadFromFile([String? configPath]) async {
    final filePath = configPath ??
        path.join(Platform.environment['HOME']!, '.cl_client_config.json');

    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return CLIConfig.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load config from $filePath: $e');
    }
  }

  /// Get default configuration
  static CLIConfig defaultConfig() {
    return const CLIConfig(serverPref: ServerPref());
  }
}
