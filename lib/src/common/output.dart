import 'dart:convert';
import 'dart:io';
import 'context.dart';

/// Output an error message and exit with code 1
void outputError(CLIContext context, String message) {
  if (context.config.outputJson) {
    final error = {'status': 'failed', 'error': message};
    // ignore: avoid_print
    print(jsonEncode(error));
  } else {
    stderr.writeln('Error: $message');
  }
  exit(1);
}

/// Output SDK result as JSON
void outputSdkResult(CLIContext context, dynamic data) {
  if (data is Map<String, dynamic>) {
    // ignore: avoid_print
    print(jsonEncode(data));
  } else if (data != null) {
    // Assume SDK model has toJson() method
    try {
      final json = (data as dynamic).toJson() as Map<String, dynamic>;
      // ignore: avoid_print
      print(jsonEncode(json));
    } catch (e) {
      // Fallback: try to encode directly
      // ignore: avoid_print
      print(jsonEncode(data));
    }
  }
}

/// Output success message
void outputSuccess(CLIContext context, String message) {
  if (context.config.outputJson) {
    final success = {'status': 'success', 'message': message};
    // ignore: avoid_print
    print(jsonEncode(success));
  } else {
    // ignore: avoid_print
    print('✓ $message');
  }
}

/// Output a list of SDK results
void outputSdkList(CLIContext context, List<dynamic> items) {
  if (context.config.outputJson) {
    final jsonItems = items.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      try {
        return (item as dynamic).toJson() as Map<String, dynamic>;
      } catch (e) {
        return item;
      }
    }).toList();
    // ignore: avoid_print
    print(jsonEncode(jsonItems));
  } else {
    // Human-readable list output
    for (final item in items) {
      // ignore: avoid_print
      print(item);
    }
  }
}
