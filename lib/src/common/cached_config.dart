import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart' as path;
import 'config.dart';

const int _cacheExpirationSeconds = 21600; // 6 hours

/// Get machine ID for encryption key derivation
/// Uses hostname as a machine identifier (pure Dart, no Flutter dependencies)
String _getMachineId() {
  try {
    // Use hostname as machine identifier
    return Platform.localHostname;
  } catch (e) {
    return 'default-machine';
  }
}

/// Get encryption key derived from machine hostname
encrypt.Key _getEncryptionKey() {
  final machineId = _getMachineId();
  final keyMaterial = 'cl-client:$machineId';
  final hash = sha256.convert(utf8.encode(keyMaterial));
  // Use first 32 bytes of hash for AES-256 key
  final keyBytes = hash.bytes.sublist(0, 32);
  return encrypt.Key.fromBase64(base64.encode(keyBytes));
}

/// Save CLI config to encrypted cache
Future<void> saveConfigToCache(CLIConfig config) async {
  final key = _getEncryptionKey();
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.gcm),
  );

  final configJson = jsonEncode(config.toJson());
  final encrypted = encrypter.encrypt(configJson, iv: iv);

  final cacheData = {
    'encrypted_config': encrypted.base64,
    'iv': iv.base64,
    'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
  };

  final cacheFile =
      File(path.join(Platform.environment['HOME']!, '.cl_dart_client_cache'));
  await cacheFile.writeAsString(jsonEncode(cacheData));

  // Set permissions to 0o600 on Unix systems
  if (!Platform.isWindows) {
    try {
      await Process.run('chmod', ['600', cacheFile.path]);
    } catch (e) {
      // Ignore chmod errors (might not have permissions or chmod not available)
    }
  }
}

/// Load CLI config from encrypted cache
Future<CLIConfig?> loadConfigFromCache() async {
  final cacheFile =
      File(path.join(Platform.environment['HOME']!, '.cl_dart_client_cache'));

  if (!await cacheFile.exists()) {
    return null;
  }

  try {
    final contents = await cacheFile.readAsString();
    final cacheData = jsonDecode(contents) as Map<String, dynamic>;

    // Check expiration
    final timestamp = cacheData['timestamp'] as num;
    final age = DateTime.now().millisecondsSinceEpoch / 1000 - timestamp;
    if (age > _cacheExpirationSeconds) {
      // Cache expired, clear it
      await clearConfigCache();
      return null;
    }

    // Decrypt config
    final key = _getEncryptionKey();
    final iv = encrypt.IV.fromBase64(cacheData['iv'] as String);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted =
        encrypt.Encrypted.fromBase64(cacheData['encrypted_config'] as String);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    final configJson = jsonDecode(decrypted) as Map<String, dynamic>;
    return CLIConfig.fromJson(configJson);
  } catch (e) {
    // Failed to load or decrypt cache, clear it
    await clearConfigCache();
    return null;
  }
}

/// Clear the configuration cache
Future<void> clearConfigCache() async {
  final cacheFile =
      File(path.join(Platform.environment['HOME']!, '.cl_dart_client_cache'));

  if (await cacheFile.exists()) {
    await cacheFile.delete();
  }
}
