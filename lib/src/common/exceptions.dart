/// Custom exceptions for CLI operations
library;

/// Base exception for CLI errors
class CLIException implements Exception {
  CLIException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exception for authentication failures
class AuthenticationException extends CLIException {
  AuthenticationException(super.message);
}

/// Exception for configuration errors
class ConfigException extends CLIException {
  ConfigException(super.message);
}
