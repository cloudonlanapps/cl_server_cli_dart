import 'dart:io';
import 'package:args/args.dart';
import 'package:cli_dart/cli_dart.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('json', help: 'Output as JSON', negatable: false)
    ..addFlag('version', help: 'Show version', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);

  // Login command
  final loginCmd = parser.addCommand('login');
  loginCmd.addOption('username', abbr: 'u', help: 'Username');
  loginCmd.addOption('password', abbr: 'p', help: 'Password');
  loginCmd.addOption('auth-url', help: 'Auth service URL');
  loginCmd.addOption('compute-url', help: 'Compute service URL');
  loginCmd.addOption('store-url', help: 'Store service URL');
  loginCmd.addOption('mqtt-url', help: 'MQTT broker URL');
  loginCmd.addFlag('no-auth', help: 'Guest mode', negatable: false);
  loginCmd.addFlag('json', help: 'JSON output', negatable: false);

  // Logout command
  parser.addCommand('logout');

  // Store command group
  final storeCmd = parser.addCommand('store');

  // Store list
  final listCmd = storeCmd.addCommand('list');
  listCmd.addOption('page', defaultsTo: '1', help: 'Page number');
  listCmd.addOption('page-size', defaultsTo: '20', help: 'Items per page');
  listCmd.addOption('search', help: 'Search query');
  listCmd.addOption('output', abbr: 'o', help: 'Output file');

  // Store upload
  final uploadCmd = storeCmd.addCommand('upload');
  uploadCmd.addOption('label', help: 'Entity label');
  uploadCmd.addOption('description', help: 'Entity description');
  uploadCmd.addOption('parent-id', help: 'Parent entity ID');
  uploadCmd.addFlag('recursive', abbr: 'r', help: 'Upload directory recursively', negatable: false);
  uploadCmd.addFlag('yes', abbr: 'y', help: 'Skip confirmation', negatable: false);

  // Store create
  final createCmd = storeCmd.addCommand('create');
  createCmd.addOption('label', help: 'Entity label');
  createCmd.addOption('description', help: 'Entity description');
  createCmd.addOption('parent-id', help: 'Parent entity ID');

  // Store get
  storeCmd.addCommand('get');

  // Store update
  final updateCmd = storeCmd.addCommand('update');
  updateCmd.addOption('label', help: 'New label');
  updateCmd.addOption('description', help: 'New description');

  // Store patch
  final patchCmd = storeCmd.addCommand('patch');
  patchCmd.addOption('label', help: 'New label');
  patchCmd.addOption('description', help: 'New description');

  // Store delete
  storeCmd.addCommand('delete');

  // Store versions
  storeCmd.addCommand('versions');

  // Store intelligence
  storeCmd.addCommand('intelligence');

  // Store face (subgroup)
  final faceCmd = storeCmd.addCommand('face');
  faceCmd.addCommand('delete');

  try {
    final results = parser.parse(arguments);

    if (results['version']) {
      // ignore: avoid_print
      print('cli-dart version $version');
      exit(0);
    }

    if (results['help'] || results.command == null) {
      // ignore: avoid_print
      print('Usage: cli-dart <command> [options]');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('Commands:');
      // ignore: avoid_print
      print('  login    Login and cache credentials');
      // ignore: avoid_print
      print('  logout   Logout and clear cache');
      // ignore: avoid_print
      print('  store    Store management commands');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print(parser.usage);
      exit(0);
    }

    final globalJson = results['json'] as bool;

    switch (results.command?.name) {
      case 'login':
        await runLoginCommand(results.command!, globalJson);
        break;

      case 'logout':
        final context = CLIContext(
          config: CLIConfig.defaultConfig().copyWith(outputJson: globalJson),
        );
        await runLogoutCommand(context);
        break;

      case 'store':
        await _handleStoreCommand(results.command!, globalJson);
        break;

      default:
        stderr.writeln('Unknown command: ${results.command?.name}');
        // ignore: avoid_print
        print(parser.usage);
        exit(1);
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    // ignore: avoid_print
    print(parser.usage);
    exit(1);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<void> _handleStoreCommand(ArgResults args, bool globalJson) async {
  final context = await loadCachedConfigOrExit(globalJson);

  switch (args.command?.name) {
    case 'list':
      await runStoreListCommand(args.command!, context);
      break;

    case 'upload':
      await runStoreUploadCommand(args.command!, context);
      break;

    case 'create':
      await runStoreCreateCommand(args.command!, context);
      break;

    case 'get':
      await runStoreGetCommand(args.command!, context);
      break;

    case 'update':
      await runStoreUpdateCommand(args.command!, context);
      break;

    case 'patch':
      await runStorePatchCommand(args.command!, context);
      break;

    case 'delete':
      await runStoreDeleteCommand(args.command!, context);
      break;

    case 'versions':
      await runStoreVersionsCommand(args.command!, context);
      break;

    case 'intelligence':
      await runStoreIntelligenceCommand(args.command!, context);
      break;

    case 'face':
      await runStoreFaceCommand(args.command!, context);
      break;

    default:
      stderr.writeln('Unknown store command: ${args.command?.name}');
      stderr.writeln('Available: list, upload, create, get, update, patch, delete, versions, intelligence, face');
      exit(1);
  }
}
