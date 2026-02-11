import '../../common/cached_config.dart';
import '../../common/config.dart';
import '../../common/context.dart';
import '../../common/output.dart';

/// Load cached config or exit with error
Future<CLIContext> loadCachedConfigOrExit(bool globalJson) async {
  final config = await loadConfigFromCache();

  if (config == null) {
    final tempContext = CLIContext(
      config: CLIConfig.defaultConfig().copyWith(outputJson: globalJson),
    );
    outputError(tempContext, 'Not logged in. Run: cli-dart login');
  }

  return CLIContext(
    config: config!.copyWith(outputJson: globalJson || config.outputJson),
  );
}
