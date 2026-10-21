import '../../../auth/services/account_service.dart';
import '../../../../shared/models/learning_page.dart';
export '../../../../shared/models/learning_page.dart';

class LearningService {
  LearningService(this.account);
  final AccountService account;
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    bool public = false,
  }) => account.request(method, path, public: public);
  Future<LearningPage> catalogue({
    int page = 1,
    String search = '',
    String category = '',
  }) async => LearningPage.decode(
    await request(
      'GET',
      Uri(
        path: '/api/v1/courses',
        queryParameters: {
          'page': '$page',
          'limit': '20',
          if (search.isNotEmpty) 'search': search,
          if (category.isNotEmpty) 'categoryId': category,
        },
      ).toString(),
      public: true,
    ),
    'courses',
  );
  Future<List<Map<String, dynamic>>> categories() async {
    final result = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final batch = LearningPage.decode(
        await request(
          'GET',
          '/api/v1/categories?page=$page&limit=20',
          public: true,
        ),
        'categories',
      );
      result.addAll(batch.items.where((c) => c['isActive'] != false));
      if (!batch.hasNext) return result;
      page++;
    }
  }

  Future<LearningPage> enrollments(int page, String status) async =>
      LearningPage.decode(
        await request(
          'GET',
          '/api/v1/enrollments/me?page=$page&limit=20&status=$status',
        ),
        'enrollments',
      );
  Future<Map<String, dynamic>> detail(String id) async {
    final data = object(
      (await request('GET', '/api/v1/courses/$id', public: true))['data'],
    );
    return object(data['course'] ?? data);
  }

  Future<void> enroll(String id) async {
    await request('POST', '/api/v1/courses/$id/enroll');
  }

  Future<List<Map<String, dynamic>>> sections(String id) async {
    final data = (await request('GET', '/api/v1/courses/$id/sections'))['data'];
    return records(data is List ? data : object(data)['sections']);
  }

  Future<List<Map<String, dynamic>>> lessons(String id) async {
    final data = (await request('GET', '/api/v1/sections/$id/lessons'))['data'];
    return records(data is List ? data : object(data)['lessons']);
  }

  Future<Map<String, dynamic>> lesson(String id) async {
    final data = object((await request('GET', '/api/v1/lessons/$id'))['data']);
    return object(data['lesson'] ?? data);
  }

  Future<Map<String, dynamic>> progress(String id) async =>
      object((await request('GET', '/api/v1/courses/$id/progress/me'))['data']);
  Future<void> start(String id) async {
    await request('PATCH', '/api/v1/lessons/$id/start');
  }

  Future<void> complete(String id) async {
    await request('PATCH', '/api/v1/lessons/$id/complete');
  }
}
