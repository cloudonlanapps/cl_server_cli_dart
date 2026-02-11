import 'package:args/args.dart';
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

/// Execute store update command
Future<void> runStoreUpdateCommand(ArgResults args, CLIContext context) async {
  final rest = args.rest;
  if (rest.isEmpty) {
    outputError(context, 'Entity ID required');
  }

  final entityId = int.tryParse(rest[0]);
  if (entityId == null) {
    outputError(context, 'Invalid entity ID: ${rest[0]}');
  }

  final label = args['label'] as String?;
  final description = args['description'] as String?;

  final manager = await getStoreManager(context);
  try {
    final result = await manager.updateEntity(
      entityId!,
      label: label ?? '',
      description: description,
    );

    if (!result.isSuccess || result.data == null) {
      outputError(context, result.error ?? 'Failed to update entity');
    }

    outputSdkResult(context, result.data);
  } finally {
    await context.cleanup();
  }
}
