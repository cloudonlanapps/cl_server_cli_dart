import 'package:args/args.dart';
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

/// Execute store create command
Future<void> runStoreCreateCommand(ArgResults args, CLIContext context) async {
  final label = args['label'] as String?;
  final description = args['description'] as String?;
  final parentId = args['parent-id'] != null
      ? int.tryParse(args['parent-id'] as String)
      : null;

  final manager = await getStoreManager(context);
  try {
    final result = await manager.createEntity(
      isCollection: true,
      label: label,
      description: description,
      parentId: parentId,
    );

    if (!result.isSuccess || result.data == null) {
      outputError(context, result.error ?? 'Failed to create entity');
    }

    outputSdkResult(context, result.data);
  } finally {
    await context.cleanup();
  }
}
