import 'package:args/args.dart';
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

/// Execute store delete command
Future<void> runStoreDeleteCommand(ArgResults args, CLIContext context) async {
  final rest = args.rest;
  if (rest.isEmpty) {
    outputError(context, 'Entity ID required');
  }

  final entityId = int.tryParse(rest[0]);
  if (entityId == null) {
    outputError(context, 'Invalid entity ID: ${rest[0]}');
  }

  final manager = await getStoreManager(context);
  try {
    final result = await manager.deleteEntity(entityId!);

    if (!result.isSuccess) {
      outputError(context, result.error ?? 'Failed to delete entity');
    }

    outputSuccess(context, 'Entity deleted successfully');
  } finally {
    await context.cleanup();
  }
}
