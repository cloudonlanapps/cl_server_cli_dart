import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

/// Execute store list command
Future<void> runStoreListCommand(ArgResults args, CLIContext context) async {
  final page = int.tryParse(args['page'] as String? ?? '1') ?? 1;
  final pageSize = int.tryParse(args['page-size'] as String? ?? '20') ?? 20;
  final search = args['search'] as String?;
  final outputFile = args['output'] as String?;

  final manager = await getStoreManager(context);
  try {
    final result = await manager.listEntities(
      page: page,
      pageSize: pageSize,
      searchQuery: search,
    );

    if (!result.isSuccess || result.data == null) {
      outputError(
          context, result.error ?? 'Failed to list entities');
    }

    // Output to console
    outputSdkResult(context, result.data);

    // Save to file if requested
    if (outputFile != null) {
      final file = File(outputFile);
      final json = jsonEncode(result.data!.toJson());
      await file.writeAsString(json);
    }
  } finally {
    await context.cleanup();
  }
}
