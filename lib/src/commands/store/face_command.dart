import 'package:args/args.dart';
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

/// Execute store face command (subgroup)
Future<void> runStoreFaceCommand(ArgResults args, CLIContext context) async {
  // Check subcommand
  if (args.command == null || args.command!.name != 'delete') {
    outputError(context, 'Usage: cli-dart store face delete <face-id>');
  }

  final rest = args.command!.rest;
  if (rest.isEmpty) {
    outputError(context, 'Face ID required');
  }

  final faceId = int.tryParse(rest[0]);
  if (faceId == null) {
    outputError(context, 'Invalid face ID: ${rest[0]}');
  }

  final manager = await getStoreManager(context);
  try {
    final result = await manager.deleteFace(faceId!);

    if (!result.isSuccess) {
      outputError(context, result.error ?? 'Failed to delete face');
    }

    outputSuccess(context, 'Face deleted successfully');
  } finally {
    await context.cleanup();
  }
}
