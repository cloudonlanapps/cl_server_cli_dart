import '../common/cached_config.dart';
import '../common/context.dart';
import '../common/output.dart';

/// Execute logout command - clears cache
Future<void> runLogoutCommand(CLIContext context) async {
  await clearConfigCache();
  outputSuccess(context, 'Logged out successfully');
}
