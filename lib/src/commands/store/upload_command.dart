import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import '../../common/context.dart';
import '../../common/output.dart';
import '../../utils/store_manager_factory.dart';

/// Execute store upload command
Future<void> runStoreUploadCommand(ArgResults args, CLIContext context) async {
  final rest = args.rest;
  if (rest.isEmpty) {
    outputError(context, 'Path required');
  }

  final uploadPath = rest[0];
  final label = args['label'] as String?;
  final description = args['description'] as String?;
  final parentId = args['parent-id'] != null
      ? int.tryParse(args['parent-id'] as String)
      : null;
  final recursive = args['recursive'] as bool? ?? false;
  final yes = args['yes'] as bool? ?? false;

  final file = File(uploadPath);
  final dir = Directory(uploadPath);

  if (await file.exists()) {
    // Single file upload
    await _uploadFile(file, label, description, parentId, context);
  } else if (await dir.exists() && recursive) {
    // Directory upload
    await _uploadDirectory(dir, parentId, yes, context);
  } else {
    outputError(context,
        'Path not found or not a directory (use --recursive for directories): $uploadPath');
  }
}

Future<void> _uploadFile(
  File file,
  String? label,
  String? description,
  int? parentId,
  CLIContext context,
) async {
  final manager = await getStoreManager(context);
  try {
    final result = await manager.createEntity(
      isCollection: false,
      label: label ?? path.basename(file.path),
      description: description,
      parentId: parentId,
      mediaPath: file.path,
    );

    if (!result.isSuccess || result.data == null) {
      outputError(context, result.error ?? 'Failed to upload file');
    }

    outputSdkResult(context, result.data);
  } finally {
    await context.cleanup();
  }
}

Future<void> _uploadDirectory(
  Directory dir,
  int? parentId,
  bool yes,
  CLIContext context,
) async {
  // Get list of image files
  final files = <File>[];
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      final ext = path.extension(entity.path).toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
        files.add(entity);
      }
    }
  }

  if (files.isEmpty) {
    outputError(context, 'No image files found in directory');
  }

  // Confirm upload
  if (!yes && !context.config.outputJson) {
    stdout.write('Upload ${files.length} files? (y/N): ');
    final confirm = stdin.readLineSync()?.toLowerCase();
    if (confirm != 'y' && confirm != 'yes') {
      outputError(context, 'Upload cancelled');
    }
  }

  // Upload files
  final manager = await getStoreManager(context);
  try {
    for (final file in files) {
      final result = await manager.createEntity(
        isCollection: false,
        label: path.basename(file.path),
        parentId: parentId,
        mediaPath: file.path,
      );

      if (!context.config.outputJson) {
        if (result.isSuccess) {
          // ignore: avoid_print
          print('✓ Uploaded: ${file.path}');
        } else {
          // ignore: avoid_print
          print('✗ Failed: ${file.path} - ${result.error}');
        }
      }
    }

    if (!context.config.outputJson) {
      // ignore: avoid_print
      print('\nUploaded ${files.length} files');
    }
  } finally {
    await context.cleanup();
  }
}
