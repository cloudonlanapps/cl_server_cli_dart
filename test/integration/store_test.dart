@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:cl_server_dart_client/cl_server_dart_client.dart';
import 'package:cli_dart/src/common/config.dart';

/// Integration tests for store operations
/// Requires:
/// - Running CL Server with store service
/// - Config file: ~/.cl_client_config.json (shared with Python CLI)
void main() {
  late ServerConfig serverConfig;
  late SessionManager session;
  late StoreManager storeManager;
  late String username;
  late String password;

  setUpAll(() async {
    // Load from config file (shared with Python CLI)
    final config = await CLIConfig.loadFromFile();

    if (config != null) {
      // Use config file settings
      serverConfig = config.toServerConfig();
      username = config.username ?? 'admin';
      password = 'admin'; // Password not stored in config
    } else {
      // Fallback to defaults
      serverConfig = const ServerConfig(
        authUrl: 'http://192.168.0.105:8010',
        computeUrl: 'http://192.168.0.105:8012',
        storeUrl: 'http://192.168.0.105:8011',
        mqttUrl: 'mqtt://192.168.0.105:1883',
      );
      username = 'admin';
      password = 'admin';
    }

    // Login and create store manager
    session = SessionManager(serverConfig: serverConfig);
    await session.login(username, password);
    storeManager = session.createStoreManager();
  });

  tearDownAll(() async {
    await session.close();
  });

  group('Store Integration', () {
    test('list entities returns results', () async {
      final result = await storeManager.listEntities(page: 1, pageSize: 10);

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.items, isNotNull);
    });

    test('create collection succeeds', () async {
      final result = await storeManager.createEntity(
        isCollection: true,
        label: 'Test Collection ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Integration test collection',
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.label, contains('Test Collection'));
      expect(result.data!.isCollection, true);

      // Cleanup: delete the created collection
      if (result.data != null) {
        await storeManager.deleteEntity(result.data!.id);
      }
    });

    test('get entity by id succeeds', () async {
      // First create an entity
      final createResult = await storeManager.createEntity(
        isCollection: true,
        label: 'Temp Entity ${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(createResult.isSuccess, true);
      final entityId = createResult.data!.id;

      // Get the entity
      final getResult = await storeManager.readEntity(entityId);

      expect(getResult.isSuccess, true);
      expect(getResult.data, isNotNull);
      expect(getResult.data!.id, entityId);

      // Cleanup
      await storeManager.deleteEntity(entityId);
    });

    test('update entity succeeds', () async {
      // Create entity
      final createResult = await storeManager.createEntity(
        isCollection: true,
        label: 'Original Label',
      );

      expect(createResult.isSuccess, true);
      final entityId = createResult.data!.id;

      // Update entity
      final updateResult = await storeManager.updateEntity(
        entityId,
        isCollection: true, // Must match original entity type
        label: 'Updated Label',
        description: 'New description',
      );

      expect(updateResult.isSuccess, true);
      expect(updateResult.data!.label, 'Updated Label');
      expect(updateResult.data!.description, 'New description');

      // Cleanup
      await storeManager.deleteEntity(entityId);
    });

    test('patch entity succeeds', () async {
      // Create entity
      final createResult = await storeManager.createEntity(
        isCollection: true,
        label: 'Original',
        description: 'Original description',
      );

      expect(createResult.isSuccess, true);
      final entityId = createResult.data!.id;

      // Patch entity (only update description)
      final patchResult = await storeManager.patchEntity(
        entityId,
        description: 'Patched description',
      );

      expect(patchResult.isSuccess, true);
      expect(patchResult.data!.description, 'Patched description');

      // Cleanup
      await storeManager.deleteEntity(entityId);
    });

    test('delete entity succeeds', () async {
      // Create entity
      final createResult = await storeManager.createEntity(
        isCollection: true,
        label: 'To Delete',
      );

      expect(createResult.isSuccess, true);
      final entityId = createResult.data!.id;

      // Delete entity
      final deleteResult = await storeManager.deleteEntity(entityId);

      expect(deleteResult.isSuccess, true);

      // Verify deletion
      final getResult = await storeManager.readEntity(entityId);
      // Entity should be soft-deleted or not found
      expect(
        getResult.isSuccess == false || getResult.data!.isDeleted == true,
        true,
      );
    });

    test('get versions for entity succeeds', () async {
      // Create entity
      final createResult = await storeManager.createEntity(
        isCollection: true,
        label: 'Versioned Entity',
      );

      expect(createResult.isSuccess, true);
      final entityId = createResult.data!.id;

      // Get versions
      final versionsResult = await storeManager.getVersions(entityId);

      expect(versionsResult.isSuccess, true);
      expect(versionsResult.data, isNotNull);
      expect(versionsResult.data!.length, greaterThan(0));

      // Cleanup
      await storeManager.deleteEntity(entityId);
    });

    test('guest mode requires authentication', () async {
      final guestManager = StoreManager.guest(
        baseUrl: serverConfig.storeUrl,
        mqttUrl: serverConfig.mqttUrl,
      );

      try {
        final result = await guestManager.listEntities(page: 1, pageSize: 10);
        // Guest mode is not enabled on this server, so expect failure
        expect(result.isSuccess, false);
        expect(result.error, contains('Unauthorized'));
      } finally {
        await guestManager.close();
      }
    });
  }, tags: 'integration');
}
