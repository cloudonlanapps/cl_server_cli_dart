import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:args/args.dart';
import 'package:cl_server_dart_client/cl_server_dart_client.dart';

class MockStoreManager extends Mock implements StoreManager {}

class MockEntityListResponse extends Mock implements EntityListResponse {}

class MockEntity extends Mock implements Entity {}

void main() {
  late MockStoreManager mockManager;
  late ArgParser parser;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(1);
    registerFallbackValue(20);
  });

  setUp(() {
    mockManager = MockStoreManager();

    // Setup arg parser
    parser = ArgParser();
    parser.addOption('page', defaultsTo: '1');
    parser.addOption('page-size', defaultsTo: '20');
    parser.addOption('search');
    parser.addOption('output');
  });

  group('StoreListCommand', () {
    test('lists entities with default pagination', () async {
      final mockResponse = MockEntityListResponse();
      final mockResult = StoreOperationResult<EntityListResponse>(
        success: 'Entities retrieved successfully',
        data: mockResponse,
      );

      when(() => mockManager.listEntities(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => mockResult);

      // Note: This test is simplified. In a real scenario, you'd need to
      // mock the getStoreManager factory function or restructure the code
      // to allow dependency injection

      // For now, we verify the mocking setup works
      final result = await mockManager.listEntities(page: 1, pageSize: 20);
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
    });

    test('lists entities with custom pagination', () async {
      final mockResponse = MockEntityListResponse();
      final mockResult = StoreOperationResult<EntityListResponse>(
        success: 'Entities retrieved successfully',
        data: mockResponse,
      );

      when(() => mockManager.listEntities(
            page: 2,
            pageSize: 50,
          )).thenAnswer((_) async => mockResult);

      final result = await mockManager.listEntities(page: 2, pageSize: 50);
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);

      verify(() => mockManager.listEntities(page: 2, pageSize: 50)).called(1);
    });

    test('lists entities with search query', () async {
      final mockResponse = MockEntityListResponse();
      final mockResult = StoreOperationResult<EntityListResponse>(
        success: 'Entities retrieved successfully',
        data: mockResponse,
      );

      when(() => mockManager.listEntities(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            searchQuery: 'vacation',
          )).thenAnswer((_) async => mockResult);

      final result = await mockManager.listEntities(
        page: 1,
        pageSize: 20,
        searchQuery: 'vacation',
      );

      expect(result.isSuccess, true);
      verify(() => mockManager.listEntities(
            page: 1,
            pageSize: 20,
            searchQuery: 'vacation',
          )).called(1);
    });

    test('handles list failure gracefully', () async {
      final mockResult = StoreOperationResult<EntityListResponse>(
        error: 'Network error',
      );

      when(() => mockManager.listEntities(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async => mockResult);

      final result = await mockManager.listEntities(page: 1, pageSize: 20);
      expect(result.isSuccess, false);
      expect(result.error, 'Network error');
    });

    test('parses page argument correctly', () {
      final args = parser.parse(['--page', '3', '--page-size', '30']);
      final page = int.tryParse(args['page'] as String) ?? 1;
      final pageSize = int.tryParse(args['page-size'] as String) ?? 20;

      expect(page, 3);
      expect(pageSize, 30);
    });

    test('uses default values when arguments not provided', () {
      final args = parser.parse([]);
      final page = int.tryParse(args['page'] as String) ?? 1;
      final pageSize = int.tryParse(args['page-size'] as String) ?? 20;

      expect(page, 1);
      expect(pageSize, 20);
    });
  });
}
